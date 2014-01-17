#!/usr/bin/env ruby

# um Ergebnisse aus Endomondo zu scrapen
# 24.12.2013
#
require 'mechanize'
require 'nokogiri'
require 'rubygems'
require 'logger'
require 'open-uri'

pages = 30

def clean(b)

    b.gsub!(/\t\t/,'')
    b.gsub!(/        \n\t/,'')
    b.gsub!(/\n          /,'')
    b.gsub!(/      /,'')
    b.gsub!(/  /,',')
    b.gsub!(/ $/,'')
    b.gsub!(/^D.*/,'')
    b.gsub!(/^\n/,'')

    return b
end


# build cache
expiration = 60 * 60

# file to store cache in
cache = "cache.txt"

cache_age = Time.new - File.new('cache.txt').mtime


a = Mechanize.new do |agent|
	agent.user_agent_alias = 'Mac Safari'
	agent.log = Logger.new(STDOUT)
	agent.log.level = Logger::ERROR
end

# if the cache age is greater than our expiration time
if cache_age > expiration
    # our cache has expired
    puts "cache has expired. fetching new headline"


    a.get ('https://www.endomondo.com/access') do |login_page|
	    my_page = login_page.form_with(:action => '?wicket:interface=:0:pageContainer:lowerSection:lowerMain:lowerMainContent:signInPanel:signInFormPanel:signInForm::IFormSubmitListener::') do |form|
		    form.email = 'XXXXXXXXXXXXXXXXXXX'
		    form.password = 'XXXXXXXXXXXXXXXXXXX'
	    end.submit

	    # jetzt suchen: workouts
        # debug puts '->,<-'	
	    workout_page = my_page.link_with(:text => 'WORKOUTS').click
	
	    # jetzt einzelne workouts
	
	    ww = workout_page.link_with(:text => 'Historie').click
	
	    # jetzt Ergebnisse finden
	    page = Nokogiri::HTML(ww.body)
        # debug pp page	
	
	    rows = page.xpath("//table/tbody/tr[position() > 0]")
	    header = rows.shift
	
	    a = clean(rows.text)

        # naechste Seite
        # Schleife bauen (i=0 to pages)

        arr = Array.new(pages)
        arr[0] = a
        puts arr[0]

        # temp variable
        interim = ww
        # debug pp ww 

    (2..pages).each do |i|
        interim = interim.link_with(:text => "#{i}").click

        page = Nokogiri::HTML(interim.body)
	   
        rows = page.xpath("//table/tbody/tr[position() > 0]")
        header = rows.shift
	
        result = clean(rows.text)

        arr[i-1] = result
        puts arr[i-1]

    end


        # write file
	    File.open(cache, "w") do |file|
            (0..pages).each do |i|
                file.puts arr[i]
            end
        end
	
        puts "cache updated"
    end
else

    # we should use our cached copy
    # read cache into a string using the read method

    data = IO.read("cache.txt")

    puts data
    puts "used cached copy"
end

