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
# craigrow
# craigrow@hotmail.com

module.exports = (robot) ->
	team = ''
	robot.hear /how (about|bout) (them|those) (.*)/i, (msg) ->
		# Find the team's city
		team = msg.match[3]
		city = getCity(team)

		# Get game data for today
		day = getDay()
		month = getMonth()
		year = getYear()
		url = 'http://mlb.mlb.com/gdcross/components/game/mlb/year_' + year + '/month_' + month + '/day_' + day + '/master_scoreboard.json'

		msg.http(url)
			.get() (err, res, body) ->
				gameData = JSON.parse(body)

		# Parse the data to see if team has a game today
				gameNumber = 0

				while gameData.data.games.game[gameNumber].home_team_city != city & gameData.data.games.game[gameNumber].away_team_city != city
					gameNumber++
					if gameData.data.games.game[gameNumber] is undefined
						break
				if gameData.data.games.game[gameNumber] is undefined
					msg.send 'The ' + team + ' do not play today'
				else
					myGame = gameData.data.games.game[gameNumber]

		# Figure out if the team is home or away
					homeAway = ''

					if myGame.home_team_city is city
						homeAway = 'home'
					else if myGame.away_team_city is city
						homeAway = 'away'
					else
						homeAway = 'error'

		# Find the opponent's name
					opponentTeam = ''
					if myGame.home_team_city is city
						opponentTeam = myGame.away_team_city
					else if myGame.away_team_city is city
						opponentTeam = myGame.home_team_city
					else
						opponentTeam = 'error'

		# Figure out if the game is in progress.
					gameStatus = myGame.status.status

					if gameStatus is "Pre-Game" or gameStatus is "Preview"
						awayProbablePitcher = myGame.away_probable_pitcher.last
						apWins = myGame.away_probable_pitcher.wins
						apLosses = myGame.away_probable_pitcher.losses
						apEra = myGame.away_probable_pitcher.era
						awayPitcherLine = awayProbablePitcher + ' ' + apWins + '-' + apLosses + ' ' + apEra

						homeProbablePitcher = myGame.home_probable_pitcher.last
						hpWins = myGame.home_probable_pitcher.wins
						hpLosses = myGame.home_probable_pitcher.losses
						hpEra = myGame.home_probable_pitcher.era
						homePitcherLine = homeProbablePitcher + ' ' + hpWins + '-' + hpLosses + ' ' + hpEra

						matchup = awayPitcherLine + ' vs ' + homePitcherLine

						if homeAway is 'home'
							msg.send 'The ' + team + ' are playing ' + opponentTeam + ' at home today.'
							msg.send matchup
						else if homeAway is 'away'
							msg.send 'The ' + team + ' are playing in ' + opponentTeam + ' today.'
							msg.send matchup

		# Find the score of each team
					if gameStatus isnt 'Pre-Game' and gameStatus isnt 'Preview'
						myTeamScore = ''
						opponentTeamScore = ''

						if city is myGame.home_team_city
							myTeamScore = parseInt(myGame.linescore.r.home, 10)
							opponentTeamScore = parseInt(myGame.linescore.r.away, 10)
						else if city is myGame.away_team_city
							myTeamScore = parseInt(myGame.linescore.r.away, 10)
							opponentTeamScore = parseInt(myGame.linescore.r.home, 10)
						else
							msg.send 'error'

		# Check if the game is over
					if gameStatus is 'Final'
						if myTeamScore > opponentTeamScore
							msg.send 'The ' + team + ' beat ' + opponentTeam + ' today! ' + myGame.linescore.r.away + '-' + myGame.linescore.r.home
						else if myTeamScore < opponentTeamScore
							msg.send 'The ' + team + ' lost to ' + opponentTeam + ' today ' + myGame.linescore.r.away + '-' + myGame.linescore.r.home

					else if gameStatus is 'In Progress'
						inning = myGame.status.inning
						inning_state = myGame.status.inning_state

						if myTeamScore > opponentTeamScore
							msg.send 'The ' + team + ' are leading ' + opponentTeam + ' in the ' + inning_state + ' of inning ' + inning + ': ' + myGame.linescore.r.away + '-' + myGame.linescore.r.home
						else if myTeamScore < opponentTeamScore
							msg.send 'The ' + team + ' are trailing ' + opponentTeam + ' in the ' + inning_state + ' of inning ' + inning + ': ' + myGame.linescore.r.away + '-' + myGame.linescore.r.home
						else if myTeamScore = opponentTeamScore
							msg.send 'The ' + team + ' and ' + opponentTeam + ' are currently tied at ' + myGame.linescore.r.away + ' in the ' + inning_state + ' of inning ' + inning

					else if gameStatus is 'Postponed'
						msg.send 'Their game seems to have been rained out.'

	robot.respond /standings (.*)|standings/i, (msg) ->
		division = msg.match[1]
		msg.http('https://erikberg.com/mlb/standings.json')
			.header('User-Agent', 'hubot-mlbot (craigrow@hotmail.com)')
			.get() (err, res, body) ->
				data = JSON.parse(body)
				standings = getStandings(data, division)

				msg.send standings

	robot.hear /what about yesterday/i, (msg) ->
		msg.send team
		day = getYesterday()
		month = getMonth()
		year = getYear()

		url = 'http://mlb.mlb.com/gdcross/components/game/mlb/year_' + year + '/month_' + month + '/day_' + day + '/master_scoreboard.json'

		getGame team, url, (myGame) ->
			city = getCity(team)
			getHomeAway myGame, city, (homeAway) ->
				getOpponentTeam myGame, city, (opponentTeam) ->
					getMyTeamScore myGame, city, homeAway, (myTeamScore) ->
						getOpponentTeamScore myGame, city, homeAway, (opponentTeamScore) ->
							if myTeamScore > opponentTeamScore
								msg.send 'They beat ' + opponentTeam + ' yesterday!'
							else if myTeamScore < opponentTeamScore
								msg.send 'They lost to ' + opponentTeam + ' yesterday :-('

	getOpponentTeamScore = (myGame, city, homeAway, callback) ->
		res = ''
		if homeAway is 'away'
			res = parseInt(myGame.linescore.r.home)
		else if homeAway is 'home'
			res = parseInt(myGame.linescore.r.away)
		callback(res)

	getMyTeamScore = (myGame, city, homeAway, callback) ->
		res = ''
		if homeAway is 'home'
			res = parseInt(myGame.linescore.r.home, 10)
		else if homeAway is 'away' 
			res = parseInt(myGame.linescore.r.away, 10)
		callback(res)

	getOpponentTeam = (myGame, city, callback) ->
		res = ''
		if myGame.home_team_city is city
			res = myGame.away_team_city
		else if myGame.away_team_city is city
			res = myGame.home_team_city
		else
			res = 'error'
		callback(res)

	getHomeAway = (myGame, city, callback) ->
		res = ''
		if myGame.home_team_city is city
			res = 'home'
		else if myGame.away_team_city is city
			res = 'away'
		else
			res = 'error'
		callback(res)

	getGame = (team, url, callback) ->
		msg = ''
		robot.http(url)
			.get() (err, res, body) ->
				gameData = JSON.parse(body)

				city = getCity(team)
				gameNumber = 0
				while gameData.data.games.game[gameNumber].home_team_city != city & gameData.data.games.game[gameNumber].away_team_city != city
					gameNumber++
					if gameData.data.games.game[gameNumber] is undefined
						break
				if gameData.data.games.game[gameNumber] is undefined
					myGame = 'They did not play yesterday'
				else
					myGame = gameData.data.games.game[gameNumber]

				msg = myGame
				callback(msg)

	getDay = () ->
		today = new Date
		dd = today.getDate()
		if dd < 10
			dd = '0' + dd
		else dd

	getYesterday = () ->
		yesterday = new Date
		dd = yesterday.getDate() - 1
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
		else if team is "Brewers" or team is "brewers"
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
		else if team is "Nationals" or team is "nationals" or team is "Nats" or team is "nats"
			city = "Washington"
		else if team is "Rays" or team is "rays"
			city = "Tampa Bay"
		else
			city = "I don't know the " + team

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