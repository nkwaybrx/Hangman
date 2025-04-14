require 'rainbow/refinement'
using Rainbow
require 'yaml'
class Game
  
  def initialize(random_word = nil, attempts = nil, word_space = nil, incorr_lett = [], corr_lett = [])
    @random_word = random_word
    @attempts = attempts
    @word_space = word_space
    @incorr_lett = incorr_lett
    @corr_lett = corr_lett
  end

  def to_yaml
    YAML.dump ({
      :random_word => @random_word,
      :attempts => @attempts,
      :word_space => @word_space,
      :incorr_lett => @incorr_lett,
      :corr_lett => @corr_lett
    })
  end

  def self.from_yaml(str)
    data = YAML.load str
    self.new(data[:random_word], data[:attempts], data[:word_space], 
             data[:incorr_lett], data[:corr_lett])
  end

  def load_game
    puts 'Would you like to load an existing game or start a new one?'
    puts "Enter 'ld' to load and 'nw' to start a new game:"
    game_choice = nil
    loop do 
      game_choice = gets.chomp 
      break if game_choice == 'ld' || game_choice == 'nw'
      puts "Unable to understand that. Please, enter 'ld' to load and 'nw' to start a new game:"
    end
    if game_choice == 'ld'
      if File.exist?('hangman_save.yaml')

        save_data = File.read('hangman_save.yaml')
        loaded_game = Game.from_yaml(save_data)
        
        # Update the current game state with the loaded data
        @random_word = loaded_game.instance_variable_get(:@random_word)
        @attempts = loaded_game.instance_variable_get(:@attempts)
        @word_space = loaded_game.instance_variable_get(:@word_space)
        @incorr_lett = loaded_game.instance_variable_get(:@incorr_lett)
        @corr_lett = loaded_game.instance_variable_get(:@corr_lett)
        
        puts 'Game has been successfully loaded.'
        return true
      else
        puts 'No saved game found. Starting a new one.'
        return false
      end
    elsif game_choice == 'nw'
      puts 'New game has been started.'
      return false
    end
  end

  def save_game
    puts "Saving game..."
    game_data = to_yaml
    
    File.open('hangman_save.yaml', 'w') do |file|
      file.write(game_data)
    end
    
    puts 'Game has been successfully saved.'
  end

  def colorize_alphabet
    @alphabet = ('A'..'Z').to_a
    @alphabet.each_with_index do |letter, index|
      if @corr_lett.include?(letter)
        @alphabet[index] = letter.green
        p @alphabet
      elsif @incorr_lett.include?(letter)
        @alphabet[index] = letter.red
        p @alphabet
      end
    end
  end

  def instructions
    puts ''
    puts 'Welcome to Hangman!'
    puts 'See the instructions below:'
    puts ''
    puts "You will have #{@attempts} attempts."
    puts 'You will lose one attempt each time the letter of your choice is wrong.'
    puts '---------------------------'
  end
  
  def pick_random_word
    words_arr = File.read('words.txt').split()
    words_arr.select! do |word|
      word.length >= 5  && word.length <= 12
    end
    @random_word = words_arr[rand(0..words_arr.length - 1)]
  end

  def show_word
    puts ''
    puts "| #{@word_space.join(' ')} |"
    puts ''
  end

  def show_alphabet
    puts @alphabet[(0..9)].join(' ')
    puts ' ' + @alphabet[(10..18)].join(' ')
    puts '   ' +  @alphabet[(19..25)].join(' ')
  end

  def pick_a_letter
    puts "Please, choose a letter or type 'sv' to save the game:"
    loop do
      @letter = gets.chomp.downcase
      if @letter == 'sv'
        save_game
        puts "Continue playing by inserting a letter or type 'qt' to quit the game:"
        @letter = gets.chomp.downcase
        
        if @letter == 'qt'
          puts 'Alright, see ya!'
          exit 1
        end
      end

      break unless @alphabet.include?(@letter.upcase.red || @letter.upcase.green) || 
                   @letter.length != 1 
      puts 'I do not expect this letter. Please, pick one of the available ones:'
      show_alphabet
    end
  end
  #в pick_a_letter добавить фунционал который говорит есть ли буква или нет и записывавает это в "alphabet"
  # в give_hing добавить функционал который подставляет буквы в @word_space
  def give_hint
    if @random_word.include?(@letter)
      @random_word.split('').each_with_index do |letter, index|
        if @letter == letter 
          @word_space[index] = letter
        end
      end
      @alphabet[@alphabet.find_index(@letter.upcase)] = @letter.upcase.green
      @corr_lett.push(@letter.upcase)
    else 
      @alphabet[@alphabet.find_index(@letter.upcase)] = @letter.upcase.red
      @incorr_lett.push(@letter.upcase)
      @attempts -= 1
    end
  end

  def play_game
    instructions
    load_choice = load_game
    colorize_alphabet if load_choice
    if load_choice == false
      @alphabet = ('A'..'Z').to_a
      pick_random_word
      @word_space = Array.new(@random_word.length, '–')
      @attempts = 7
    end
    
    until @attempts == 0
      puts "At this moment you have: #{@attempts} attempts."
      show_word
      show_alphabet
      puts @random_word
      pick_a_letter
      give_hint
      
      if @word_space.join('') == @random_word
        puts 'WIN WIN WIN! You solved the word!'
        puts 'Would you like to play again (type p) or quit (type qt)?'
        decision = nil
        loop do
          decision = gets.chomp
          break if decision == 'p' || decision == 'qt'
          puts "Cannot recognise that. Please, type 'p' to play or 'qt' to quit:"
        end
        if decision == 'p'
          play_game
        else
          puts 'Bye-bye!'
          exit 1
        end
      end
    end
    puts "Unfortunately, you lost. The word was #{@random_word}" 
    puts 'Would you like to play again (type p) or quit (type qt)?'
    decision = nil
    loop do
        decision = gets.chomp
        break if decision == 'p' || decision == 'qt'
        puts "Cannot recognise that. Please, type 'p' to play or 'qt' to quit:"
    end
    if decision == 'p'
      play_game
    else
      puts 'Bye-bye!'
      exit 1
    end
  end

end

game = Game.new
game.play_game