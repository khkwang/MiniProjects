class Array
  def random
    if respond_to? 'sample'
      random = sample
    else
      random = choice
    end
    random
  end
end

class RouletteTable
  SLOTS = [-1,27,10,25,29,12,8,19,31,18,6,21,33,16,4,23,35,14,2,0,28,9,26,30,11,7,20,32,17,5,22,34,15,3,24,36,13,1]

  def initialize(slots)
    @slots = slots
  end
  
  def spin
    @slots.random
  end
  
  def self.even(num)
    num != -1 && num != 0 && num % 2 == 0
  end
  
  def self.odd(num)
    num != -1 && num != 0 && num % 2 == 1
  end
  
  def self.zero(num)
    num == -1 || num == 0
  end

end

class RouletteGame
  
  attr_reader :rounds, :min_wager, :starting_cash, :result, :prev_result
  attr_accessor :wager, :won_game, :keep_playing, :won_round, :cash
  
  class Bet
    EVEN = Proc.new do |rg|
      rg.won_round = RouletteTable::even(rg.result)
      if rg.won_round
        rg.cash = rg.cash + rg.wager * 2
      end
    end
    
    ODD = Proc.new do |rg|
      rg.won_round = RouletteTable::odd(rg.result)
      if rg.won_round
        rg.cash = rg.cash + rg.wager * 2
      end
    end
    
    def self.random_even_or_odd
      [EVEN, ODD].random
    end
    
    OPPOSITE_EVEN_ODD = Proc.new do |rg|
      if rg.prev_result.nil? || RouletteTable::zero(rg.prev_result)
        rg.won_round = RouletteTable::odd(rg.result)
      elsif RouletteTable::odd(rg.prev_result)
        rg.won_round = RouletteTable::even(rg.result)
      elsif RouletteTable::even(rg.prev_result)
        rg.won_round = RouletteTable::odd(rg.result)
      end
      if rg.won_round
        rg.cash = rg.cash + rg.wager * 2
      end
    end
    
  end
  
  class Strategy
    def self.double_all_or_nothing(goal)
      Proc.new do |rg|
        if rg.won_round.nil? || rg.won_round
          rg.wager = rg.min_wager
          if rg.cash >= rg.starting_cash + goal
            rg.keep_playing = false
          end
        else
          rg.wager = rg.wager * 2
        end
      end
    end
    
    DOUBLE_QUIT_AFTER_WIN = Proc.new do |rg|
      if rg.won_round.nil?
        rg.wager = rg.min_wager
      elsif rg.won_round
        rg.keep_playing = false
      else
        rg.wager = rg.wager * 2
      end
    end   
    
  end
  
  def initialize(starting_cash, strategy, bet, min_wager)
    @starting_cash = starting_cash
    @strategy = strategy
    @bet = bet
    @min_wager = min_wager
    @cash = starting_cash
    @won_round = nil
    @won_game = false
    @keep_playing = true
    @rounds = 0
    @roulette_table = RouletteTable.new(RouletteTable::SLOTS)
  end
  
  def play
    @strategy.call self
    while @keep_playing && @cash > 0
      @wager = [@wager, @cash].min
      @cash = @cash - @wager
      @prev_result = @result
      @result = @roulette_table.spin
      @rounds = @rounds + 1
      @bet.call self
      @strategy.call self
    end
    won_game
  end
  
  def profit
    @cash - @starting_cash
  end
  
  def won_game
    @cash >= @starting_cash
  end
  
end

class RouletteGames
  
  attr_reader :times_played, :times_won
  
  def initialize(starting_cash, strategy, bet, min_wager, max_games=1000000, max_diff=0.001)
    @starting_cash = starting_cash
    @strategy = strategy
    @bet = bet
    @min_wager = min_wager
    @max_games = max_games
    @max_diff = max_diff
    @times_played = 0
    @times_won = 0
    @winning_rate_sum = 0
    @profits = []
    @rounds = []
    #@winning_rates = []
  end
  
  def start
    while !results_converged? && @times_played < @max_games
      roulette_game = RouletteGame.new(@starting_cash, @strategy, @bet, @min_wager)
      won = roulette_game.play
      if won
        @times_won = @times_won + 1
      end
      @times_played = @times_played + 1
      @profits << roulette_game.profit
      @rounds << roulette_game.rounds
      @winning_rate_sum = @winning_rate_sum + winning_rate
      #@winning_rates << winning_rate
    end
  end
  
  def results_converged?
    (((@winning_rate_sum / @times_played.to_f) - winning_rate + 100).abs / @times_played.to_f) < @max_diff
    #num_to_check = 1000
    #if @times_played < num_to_check
    #  converged = false
    #else
    #  converged = true
    #end
    #num_to_check = [@times_played, num_to_check].min
    #@winning_rates[-num_to_check.. @times_played].each do |wr|
    #  converged = converged && (wr - winning_rate).abs/winning_rate < @max_diff
    #end
    #converged
  end
  
  def winning_rate
    @times_won.to_f/@times_played.to_f * 100
  end
  
  def total_profit
    total = 0
    @profits.each do |profit|
      total = total + profit
    end
    total.to_f
  end
  
  def average_profit
    total_profit.to_f / @profits.size.to_f
  end
  
  def average_rounds
    total = 0
    @rounds.each do |nRounds|
      total = total + nRounds
    end
    total.to_f / @rounds.size.to_f
  end
  
  def print_results
    puts "------------------------------"
    puts "Winning Rate : %0.2f%" % [winning_rate]
    puts "Avg profit : %0.2f" % [average_profit]
    puts "Avg rounds played : %0.2f" % [average_rounds]
    puts "Times played : #{times_played}"
    puts "Times won : #{times_won}"
    puts "Total profit : : %0.2f" % [total_profit]
      puts "------------------------------"
  end
end

starting_cash = 250
goal = 200

bet = RouletteGame::Bet::EVEN
jmin_wager = 250
jstrat = RouletteGame::Strategy::double_all_or_nothing(goal)
rgs = RouletteGames.new(starting_cash, jstrat, bet, jmin_wager)
rgs.start
rgs.print_results

bet = RouletteGame::Bet::ODD
jmin_wager = 250
jstrat = RouletteGame::Strategy::double_all_or_nothing(goal)
rgs = RouletteGames.new(starting_cash, jstrat, bet, jmin_wager)
rgs.start
rgs.print_results

bet = RouletteGame::Bet::random_even_or_odd
jmin_wager = 250
jstrat = RouletteGame::Strategy::double_all_or_nothing(goal)
rgs = RouletteGames.new(starting_cash, jstrat, bet, jmin_wager)
rgs.start
rgs.print_results

bet = RouletteGame::Bet::OPPOSITE_EVEN_ODD
jmin_wager = 250
jstrat = RouletteGame::Strategy::double_all_or_nothing(goal)
rgs = RouletteGames.new(starting_cash, jstrat, bet, jmin_wager)
rgs.start
rgs.print_results

'''tstrat = RouletteGame::Strategy::DOUBLE_QUIT_AFTER_WIN
rgs = RouletteGames.new(starting_cash, tstrat, bet, goal)
rgs.start
rgs.print_results


bet = RouletteGame::Bet::EVEN

jstrat = RouletteGame::Strategy::double_all_or_nothing(goal)
rgs = RouletteGames.new(starting_cash, jstrat, bet, jmin_wager)
rgs.start
rgs.print_results

tstrat = RouletteGame::Strategy::DOUBLE_QUIT_AFTER_WIN
rgs = RouletteGames.new(starting_cash, tstrat, bet, goal)
rgs.start
rgs.print_results'''