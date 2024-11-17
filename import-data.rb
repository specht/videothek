#!/usr/bin/env ruby

require 'json'
require 'mysql2'

client = Mysql2::Client.new(
    host: ENV['MYSQL_HOST'],
    username: ENV['MYSQL_USER'],
    password: ENV['MYSQL_PASSWORD'],
    database: ENV['MYSQL_DATABASE']
)

File.open('genres.txt') do |f|
    query = client.prepare("INSERT IGNORE INTO genre (id, name) VALUES (?, ?)")
    f.each_line do |line|
        data = JSON.parse(line)
        puts "Importing genre: #{data['name']}"
        query.execute(data['id'], data['name'])
    end
end

File.open('movies.txt') do |f|
    query = client.prepare("INSERT IGNORE INTO movie (id, title, year, runtime, rating) VALUES (?, ?, ?, ?, ?)")
    query2 = client.prepare("INSERT IGNORE INTO movie_genre (movie_id, genre_id) VALUES (?, ?)")
    f.each_line do |line|
        data = JSON.parse(line)
        puts "Importing movie: #{data['year']} - #{data['title']}"
        query.execute(data['id'], data['title'], data['year'], data['runtime'], data['rating'])
        data['genres'].each do |genre|
            query2.execute(data['id'], genre)
        end
    end
end
