require 'sinatra'
require 'twilio-rb'
require 'pusher'
require 'meta-spotify'

#TODO: use slanger
Pusher.app_id = '15045'
Pusher.key    = '78ed511f5afa5e2ceffc'
Pusher.secret = '6dcadb28cebd31662232'

post '/twilio' do
  channel = 'request-line-' + params['To'].gsub(/^\D/, '')

  # select the most popular track for that query available in 'gb' territory
  track = MetaSpotify::Track.search(params['Body'])[:tracks].
    select { |o| o.album.available_territories.include? 'gb' }.
    max { |a,b| a.popularity <=> b.popularity }

  response_message = if track
    Pusher[channel].trigger!('sms', { number: params['From'].chars.to_a[-5,5].join, track_uri: track.uri })
    "Thanks! You requested \"#{track.name}\" by #{track.artists.first.name}. Listen out for your request shortly!"
  else
    "Sorry, we couldn't find any songs with that request. Try another request?"
  end

  Twilio::TwiML.build { |r| r.sms response_message }
end
