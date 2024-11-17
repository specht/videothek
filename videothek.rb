#!/usr/bin/env ruby

require 'tty-prompt'
require 'mysql2'

PROMPT = TTY::Prompt.new
PROMPT.on(:keyescape) { puts; throw :abort, -1 }

CLIENT = Mysql2::Client.new(
    host: ENV['MYSQL_HOST'],
    username: ENV['MYSQL_USER'],
    password: ENV['MYSQL_PASSWORD'],
    database: ENV['MYSQL_DATABASE']
)

def choose_with_query(prompt, query, handler, &block)
    loop do
        choices = []
        id = catch(:abort) do
            PROMPT.select(prompt) do |menu|
                index = 0
                CLIENT.query(query).each do |row|
                    result = yield(row, index)
                    index += 1
                    menu.choice result[1], result[0]
                end
                menu.choice '(zurück)', -1
            end
        end
        return if id == -1 || id.nil?
        send(handler, id)
    end
end

def show_movie(movie_id)
    movie = CLIENT.query("SELECT * FROM movie WHERE id = #{movie_id}").first
    puts "Titel    : #{movie['title']}"
    puts "Jahr     : #{movie['year']}"
    puts "Laufzeit : #{movie['runtime']} Minuten"
    puts "Bewertung: #{movie['rating']} Sterne"
    choices = []
    choices << {name: 'Zurück', value: -1}
    choice = PROMPT.select('', choices)
    return if choice == -1
end

def browse_movies_by_genre(genre_id)
    # TODO: Query hier reinschreiben: Gib ID, Titel und Jahr
    # aller Filme zurück, deren Genre gleich genre_id ist,
    # geordnet nach Filmtitel und Erscheinungsjahr
    query = ""
    choose_with_query("Bitte wähle einen Film:", query, :show_movie) do |row|
        [row['id'], "#{row['title']} (#{row['year']})"]
    end
end

puts "Willkommen in der Videothek!"

loop do
    choice = catch(:abort) do
        PROMPT.select('Bitte wähle eine Option:') do |menu|
            menu.choice 'Genres durchstöbern', 1
            menu.choice 'Beenden', -1
        end
    end
    if choice == -1
        puts "Bitte beehren Sie uns wieder."
        exit
    elsif choice == 1
        query = "SELECT * FROM genre ORDER BY genre.name ASC"
        choose_with_query("Bitte wähle ein Genre:", query, :browse_movies_by_genre) do |row|
            [row['id'], row['name']]
        end
    end
end
