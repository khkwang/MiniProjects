class Towers
  
  def initialize(numDisks)
    @numDisks = numDisks
    @towers = [[],[],[]]
    numDisks.downto(1) {|i| @towers[0].push(i)}
  end
  
  def print_towers()
    3.times do |tower_num|
      (@numDisks-@towers[tower_num].size).times do |i|
        puts
      end
      (@towers[tower_num].size-1).downto(0) do |i|
        print " "*((@numDisks-@towers[tower_num][i]))
        puts '__'*@towers[tower_num][i]
      end
      puts
      puts '------------------------------------------------'
    end
  end
  
  def move(from, to)
    disk = @towers[from].pop
    if disk.nil?
      raise "tower is empty"
    elsif @towers[to].size > 0 and disk > @towers[to][-1]
      raise "trying to stack #{disk} onto #{@towers[to][-1]}"
    end
    @towers[to].push(disk)
    puts "\e[H\e[2J"
    print_towers
    sleep(0.005)
  end
  
  def numDisks(i)
    @towers[i].size
  end
end

def solve(t)
  _solve(t, t.numDisks(0), 0, 2)
end

def _solve(t, n, from, to)
  buf = Math.log2(7&~(2**to|2**from)).to_i
  return if n == 0
  _solve(t, n-1, from, buf)
  t.move(from, to)
  _solve(t, n-1, buf, to)
end

t = Towers.new(14)
solve(t)
  
