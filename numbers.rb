# coding: utf-8
require 'test/unit'

SMALL = %w[noll ett två tre fyra fem sex sju åtta nio tio elva tolv]

def to_string(nr, genus='ett')
  {
    miljard: 1_000_000_000,
    miljon: 1_000_000,
    tusen: 1_000
  }.each do |word, scale|
    if nr >= scale && nr % scale == 0
      return to_string(nr / scale, word == :tusen ? 'ett' : 'en') +
             word.to_s + (word == :tusen || nr / scale % 10 == 1 ? '' : 'er')
    end
  end

  if (100...1000).include?(nr) && nr % 100 == 0
    return to_string(nr / 100) + 'hundra'
  end

  case nr
  when 1 then genus
  when 0..12 then SMALL[nr]
  when 13, 17, 19 then to_string(nr - 10).chomp('o') + 'tton'
  when 14 then 'fjorton'
  when 15, 16 then to_string(nr - 10) + 'ton'
  when 18 then 'arton'
  when 20 then 'tjugo'
  when 40, 50, 60, 80 then to_string(nr / 10).chomp('a').chomp('t') + 'tio'
  when 30, 70, 90 then to_string(nr / 10).chomp('a').chomp('o') + 'ttio'
  when 21..99 then split(nr, 10)
  when 101..999 then split(nr, 100)
  when 1001..999_999 then split(nr, 1000)
  when 1_000_001..999_999_999 then split(nr, 1_000_000)
  when 1_000_000_001..999_999_999_999 then split(nr, 1_000_000_000)
  end
end

def split(nr, scale)
  to_string(nr / scale * scale) + to_string(nr % scale)
end

TABLE = {
  fjorton: 14,
  arton: 18,
  nitton: 19,
  tjugo: 20,
  fyrtio: 40,
  åttio: 80,
  nittio: 90,
  tusen: 1000,
  miljon: 1_000_000,
  miljard: 1_000_000_000
}

def to_number(word)
  result = []
  last_sum = chunkify(word.gsub(/ +/, '')).reduce(0) do |sum, chunk|
    case chunk
    when *SMALL
      sum + SMALL.index(chunk)
    when 'en', 'ett'
      sum + 1
    when /(tre|fem|sex|sju)t?ton/
      sum + 10 + to_number($1)
    when /(fjor|ar|nit)ton|tjugo|(fyr|åt|nit)tio/
      sum + TABLE[chunk.to_sym]
    when /(tre|fem|sex|sju)t?tio/
      sum + to_number($1) * 10
    when 'hundra'
      [sum, 1].max * 100
    when /(tusen|miljon|miljard)/
      # Handle "tusen miljoner", "tusen miljarder", etc.
      if (1000...1_000_000).include?(result.last) && chunk.start_with?('m')
        sum += result.last
        result = result[0..-2]
      end
      # Save what we have so far...
      result << [sum, 1].max * TABLE[$1.to_sym]
      # ...and start on the next part.
      0
    else raise RuntimeError, chunk
    end
  end
  result << last_sum
  result.reduce(:+)
end

PARTS = %w[(?:tret fjor fem sex sjut ar nit)ton
           tjugo
           (?:tret fyr fem sex sjut åt nit)tio
           hundra
           tusen
           milj(?:on ard)(?:er)?
           en] + SMALL

def chunkify(word)
  word.scan(/#{PARTS.join('|')}/)
end

class NumbersTest < Test::Unit::TestCase
  def test_a_few
    check 'noll', 0
    check 'ett', 1
    check 'två', 2
    check 'tre', 3
    check 'fyra', 4
    check 'fem', 5
    check 'sex', 6
    check 'sju', 7
    check 'åtta', 8
    check 'nio', 9
    check 'tio', 10
    check 'elva', 11
    check 'tolv', 12
    check 'tretton', 13
    check 'fjorton', 14
    check 'femton', 15
    check 'sexton', 16
    check 'sjutton', 17
    check 'arton', 18
    check 'nitton', 19
    check 'tjugo', 20
    check 'tjugoett', 21
    check 'tjugotvå', 22
    check 'tjugotre', 23
    check 'trettio', 30
    check 'trettioett', 31
    check 'fyrtio', 40
    check 'fyrtiofyra', 44
    check 'femtiofem', 55
    check 'sextiosex', 66
    check 'sjuttiosju', 77
    check 'åttioåtta', 88
    check 'nittionio', 99
    check 'etthundra', 100
    check 'etthundraett', 101
    check 'etthundrafemtiosju', 157
    check 'tvåhundra', 200
    check 'tvåhundratio', 210
    check 'sjuhundratrettiotvå', 732
    check 'etttusen', 1000
    check 'etttusentvåhundraåttioåtta', 1288
    check 'tiotusen', 10_000
    check 'tolvtusenfemhundrafyra', 12_504
    check 'nittioåttatusensjuhundrasextiofem', 98_765
    check 'enmiljon', 1_000_000
    check 'tvåmiljonertrettiotusensjuhundra', 2_030_700
    check 'enmiljard', 1_000_000_000
    check ('etthundratjugotre miljarder fyrahundrafemtiosex miljoner ' +
           'sjuhundraåttionio tusen etthundratjugotre').gsub(' ', ''),
          123_456_789_123
  end

  def test_difficult
    assert_equal 21, to_number('tjugoett')
    assert_equal 21, to_number('tjugoen')
    assert_equal 100, to_number('hundra')
    assert_equal 150, to_number('hundrafemtio')
    assert_equal 150_000_000_000, to_number('hundrafemtio miljarder')
    assert_equal 1000, to_number('tusen')
    assert_equal 2_000_000_000, to_number('två tusen miljoner')
  end

  def test_many
    nr = 1
    while nr < 1_000_000_000_000
      # p [nr, chunkify(to_string(nr)).join(' ')]
      assert_equal nr, to_number(to_string(nr))
      nr = nr * 18 / 17 + 1
    end
  end

  def check(word, nr)
    assert_equal word, to_string(nr)
    assert_equal nr, to_number(word)
  end
end
