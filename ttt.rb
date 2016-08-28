require 'pry'

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                  [[1, 5, 9], [3, 5, 7]]

  INITIAL_MARKER = ' '.freeze

  def initialize
    @squares = {}
    reset
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    puts ""
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def five_is_avaiable
    @squares[5].marker == INITIAL_MARKER
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def offense_move
    WINNING_LINES.each do |line|
      if count_computer_marker(@squares.values_at(*line)) == 2
        return line.select {|num| @squares[num].marker == INITIAL_MARKER }.first
      end
    end
      nil
  end

  def defense_move
    WINNING_LINES.each do |line|
      if count_human_marker(@squares.values_at(*line)) == 2
        return line.select {|num| @squares[num].marker == INITIAL_MARKER }.first
      end
    end
      nil
  end

  def count_human_marker(squares)
    squares.collect(&:marker).count(TTTGame::HUMAN_MARKER)
  end

  def count_computer_marker(squares)
    squares.collect(&:marker).count(TTTGame::COMPUTER_MARKER)
  end

  def winning_marker
    WINNING_LINES.each do |line|
      if count_human_marker(@squares.values_at(*line)) == 3
        return TTTGame::HUMAN_MARKER
      elsif count_computer_marker(@squares.values_at(*line)) == 3
        return TTTGame::COMPUTER_MARKER
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end
end

class Square
  INITIAL_MARKER = ' '.freeze

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == Board::INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end
end

class Player
  attr_accessor :score
  attr_reader :marker

  def initialize(marker, score)
    @marker = marker
    @score = 0
  end
end

class TTTGame
  HUMAN_MARKER = "X".freeze
  COMPUTER_MARKER = "O".freeze
  FIRST_TO_MOVE = HUMAN_MARKER

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Player.new(HUMAN_MARKER, 0)
    @computer = Player.new(COMPUTER_MARKER, 0)
    @current_marker = FIRST_TO_MOVE
  end

  def play
    clear
    display_welcome_message

    loop do
      loop do
        display_board
        loop do
          current_player_moves
          break if board.someone_won? || board.full?
          clear_screen_and_display_board if human_turn?
        end
        display_result_and_update_score
        display_score
        break if champion?(computer, human)
        next_game
      end
        break unless play_again?
        game = TTTGame.new
        game.play
    end

    display_goodbye_message
  end

  private

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
    puts ""
  end

  def display_goodbye_message
    puts "Thank you for playing. Goodbye!"
  end

  def champion?(computer, human)
    computer.score == 5 || human.score == 5
  end

  def display_board
    puts "You're an #{human.marker} Computer is an #{computer.marker}"
    puts ""
    board.draw
    puts ""
  end

  def clear_screen_and_display_board
    clear
    puts "You're an #{human.marker} Computer is an #{computer.marker}"
    puts ""
    board.draw
  end

  def join_or(array)
   if array.size > 2
    str = array.join(", ")
    str.gsub!(str[-1], "or #{str[-1]}")
   else
    str = array.join(" OR ")
   end
    str
  end

  def human_moves
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice"
    end
    board[square] = human.marker
  end

  def computer_moves
    square = nil
    square ||= board.offense_move
    square ||= board.defense_move
    square ||= 5 if board.five_is_avaiable
    square ||= board.unmarked_keys.to_a.sample
    board[square] = COMPUTER_MARKER
  end

  def display_result_and_update_score
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "You won!"
      human.score += 1
    when computer.marker
      puts "Computer won!"
      computer.score += 1
    else
      puts "It's a tie"
    end
  end

  def display_score
    puts "Human: #{human.score}  Computer: #{computer.score}"
  end


  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %(y n).include?(answer)
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def clear
    system 'clear'
  end

  def next_game
    board.reset
    @current_marker = FIRST_TO_MOVE
  end

  def new_game
    board.reset
    clear
  end

  def reset
    board.reset
    player.score = 0
    computer.score = 0
    @current_marker = FIRST_TO_MOVE
    clear
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def current_player_moves
    if human_turn?
      puts "Choose a square (#{join_or(board.unmarked_keys)})"
      human_moves
      @current_marker = COMPUTER_MARKER
    else
      computer_moves
      @current_marker = HUMAN_MARKER
    end
  end

  def human_turn?
    @current_marker == HUMAN_MARKER
  end
end

game = TTTGame.new
game.play
