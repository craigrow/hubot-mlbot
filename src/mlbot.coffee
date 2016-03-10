# Description:
#   Get MLB scores and standings
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   how bout|about them|those <team name> - tells you how your team did yesterday
#   standings - gives you the standings for each MLB division
#   standdings alw|alc|ale|nlw|nlc|nle - gives you divisional standings
#
# Author:
#   craigrow
#   craigrow@hotmail.com

module.exports = (robot) ->
  robot.hear /how (about|bout) (them|those) (.*)/i, (msg) ->
    team = msg.match[3]

    city = getCity(team)
    day = getDay()
    month = getMonth()
    year = getYear()

    url = 'http://mlb.mlb.com/gdcross/components/game/mlb/year_' + year + '/month_' + month + '/day_' + day + '/master_scoreboard.json'
    #msg.send "url: " + url

    msg.http(url)
      .get() (err, res, body) ->
        if res.statusCode is 404
          msg.send "Sorry, it appears there were no games yesterday"
          return
        result = JSON.parse(body)

        i = 0

        while result.data.games.game[i].home_team_city != city & result.data.games.game[i].away_team_city != city
            i++
            if result.data.games.game[i] is undefined
              break

        if result.data.games is undefined or result.data.games.game[i] is undefined
          msg.send "The " + team + " did not play yesterday"
        else
          away_team_city = result.data.games.game[i].away_team_city
          away_team_score = result.data.games.game[i].linescore.r.away
          home_team_city = result.data.games.game[i].home_team_city
          home_team_score = result.data.games.game[i].linescore.r.home

          winner = findWinner(home_team_city, home_team_score, away_team_city, away_team_score, city)

          msg.send "The " + team + " " + winner + " yesterday"

          gamescore = away_team_city + " "  + away_team_score + " at " + home_team_city + " " + home_team_score

          msg.send gamescore

  robot.respond /standings (.*)|standings/i, (msg) ->
    division = msg.match[1]
    msg.http('https://erikberg.com/mlb/standings.json')
      .header('User-Agent', 'hubot-mlbot (craigrow@hotmail.com)')
      .get() (err, res, body) ->
        data = JSON.parse(body)
        standings = getStandings(data, division)

        msg.send standings

  getDay = () ->
    today = new Date
    dd = today.getDate() - 1
    if dd < 10
      dd = '0' + dd
    else dd

  getMonth = () ->
    today = new Date
    mm = today.getMonth()
    mm = mm + 1
    if mm < 10
      mm = '0' + mm
    else mm

  getYear = () ->
    today = new Date
    yyyy = today.getFullYear()

  getCity = (team) ->
    if team is "Mariners" or team is "mariners"
      city = "Seattle"
    else if team is "Angels" or team is "angels"
      city = "LA Angels"
    else if team is "Astros" or team is "astros"
      city = "Houston"
    else if team is "Rangers" or team is "rangers"
      city = "Texas"
    else if team is "Athletics" or team is "athletics" or team is "a's" or team is "A's"
      city = "Oakland"
    else if team is "Royals" or team is "royals"
      city = "Kansas City"
    else if team is "Twins" or team is "twins"
      city = "Minnesota"
    else if team is "White Sox" or team is "white sox"
      city = "Chi White Sox"
    else if team is "Tigers" or team is "tigers"
      city = "Detroit"
    else if team is "Indians" or team is "indians"
      city = "Cleveland"
    else if team is "Orioles" or team is "orioles"
      city = "Baltimore"
    else if team is "Red Sox" or team is "red sox" or team is "sox" or team is "Sox"
      city = "Boston"
    else if team is "Yankees" or team is "yankees"
      city = "NY Yankees"
    else if team is "Blue Jays" or team is "blue jays" or team is "Jays" or team is "jays"
      city = "Toronto"
    else if team is "Dodgers" or team is "dodgers"
      city = "LA Dodgers"
    else if team is "Giants" or team is "giants"
      city = "San Francisco"
    else if team is "Padres" or team is "padres"
      city = "San Diego"
    else if team is "Rockies" or team is "rockies"
      city = "Colorado"
    else if team is "Reds" or team is "reds"
      city = "Cincinnati"
    else if team is "Cubs" or team is "cubs" or team is "cubbies" or team is "Cubbies"
      city = "Chi Cubs"
    else if team is "Brewers" or "brewers"
      city = "Milwaukee"
    else if team is "Cardinals" or team is "cardinals" or team is "cards" or team is "Cards"
      city = "St. Louis"
    else if team is "Pirates" or team is "pirates"
      city = "Pittsburgh"
    else if team is "Phillies" or team is "phillies"
      city = "Philadelphia"
    else if team is "Mets" or team is "mets"
      city = "NY Mets"
    else if team is "Braves" or team is "braves"
      city = "Atlanta"
    else if team is "Marlins" or team is "marlins"
      city = "Miami"
    else if team is "Nationals" or "nationals" or "Nats" or "nats"
      city = "Washington"
    else if team is "Rays" or team is "rays"
      city = "Tampa Bay"
    else
      city = "I don't know the " + team

  findWinner = (home_team_city, home_team_score, away_team_city, away_team_score, city) ->
    if home_team_score > away_team_score and home_team_city is city
      "won"
    else if home_team_score > away_team_score and away_team_city is city
      "lost"
    else if away_team_score > home_team_score and home_team_city is city
      "lost"
    else if away_team_score > home_team_score and away_team_city is city
      "won"
    else
      "error"

  getStandings = (data, division) ->
    alCentral = """

    American League Central
    =======================
    #{data.standing[0].last_name} \t #{data.standing[0].won}-#{data.standing[0].lost}
    #{data.standing[1].last_name} \t #{data.standing[1].won}-#{data.standing[1].lost}
    #{data.standing[2].last_name} \t #{data.standing[2].won}-#{data.standing[2].lost}
    #{data.standing[3].last_name} \t #{data.standing[3].won}-#{data.standing[3].lost}
    #{data.standing[4].last_name} \t #{data.standing[4].won}-#{data.standing[4].lost}
    
    """

    alEast = """

    American League East
    =======================
    #{data.standing[5].last_name} \t #{data.standing[5].won}-#{data.standing[5].lost}
    #{data.standing[6].last_name} \t #{data.standing[6].won}-#{data.standing[6].lost}
    #{data.standing[7].last_name} \t #{data.standing[7].won}-#{data.standing[7].lost}
    #{data.standing[8].last_name} \t #{data.standing[8].won}-#{data.standing[8].lost}
    #{data.standing[9].last_name} \t #{data.standing[9].won}-#{data.standing[9].lost}
    
    """

    alWest = """

    American League West
    =======================
    #{data.standing[10].last_name} \t #{data.standing[10].won}-#{data.standing[10].lost}
    #{data.standing[11].last_name} \t #{data.standing[11].won}-#{data.standing[11].lost}
    #{data.standing[12].last_name} \t #{data.standing[12].won}-#{data.standing[12].lost}
    #{data.standing[13].last_name} \t #{data.standing[13].won}-#{data.standing[13].lost}
    #{data.standing[14].last_name} \t #{data.standing[14].won}-#{data.standing[14].lost}
    
    """

    nlCentral = """

    National League Central
    =======================

    #{data.standing[15].last_name} \t #{data.standing[15].won}-#{data.standing[15].lost}
    #{data.standing[16].last_name} \t #{data.standing[16].won}-#{data.standing[16].lost}
    #{data.standing[17].last_name} \t #{data.standing[17].won}-#{data.standing[17].lost}
    #{data.standing[18].last_name} \t #{data.standing[18].won}-#{data.standing[18].lost}
    #{data.standing[19].last_name} \t #{data.standing[19].won}-#{data.standing[19].lost}
    
    """

    nlEast = """

    National League East
    =======================
    #{data.standing[20].last_name} \t #{data.standing[20].won}-#{data.standing[20].lost}
    #{data.standing[21].last_name} \t #{data.standing[21].won}-#{data.standing[21].lost}
    #{data.standing[22].last_name} \t #{data.standing[22].won}-#{data.standing[22].lost}
    #{data.standing[23].last_name} \t #{data.standing[23].won}-#{data.standing[23].lost}
    #{data.standing[24].last_name} \t #{data.standing[24].won}-#{data.standing[24].lost}
    
    """

    nlWest = """

    National League West
    =======================
    #{data.standing[25].last_name} \t #{data.standing[25].won}-#{data.standing[25].lost}
    #{data.standing[26].last_name} \t #{data.standing[26].won}-#{data.standing[26].lost}
    #{data.standing[27].last_name} \t #{data.standing[27].won}-#{data.standing[27].lost}
    #{data.standing[28].last_name} \t #{data.standing[28].won}-#{data.standing[28].lost}
    #{data.standing[29].last_name} \t #{data.standing[29].won}-#{data.standing[29].lost}
    
    """
    
    if division is "alc"
      standings = alCentral
    else if division is "ale"
      standings = alEast
    else if division is "alw"
      standings = alWest
    else if division is "nlc"
      standings = nlCentral
    else if division is "nle"
      standings = nlEast
    else if division is "nlw"
      standings = nlWest
    else
      standings = alWest + alCentral + alEast + nlWest + nlCentral + nlEast