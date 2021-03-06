Bundler.require
class Command

  def initialize 
    @yahoo = Kabu::Yahoo.new
    @k_db  = Kabu::KDb.new
  end

  def update(options = {})
    args = {"from" => nil, 
            "to"   =>nil,
            "code" =>nil,
            "codefrom" =>nil,
            "stop" => false,
    }.merge(options)
    p args
    args["from"] = Date.parse args["from"]
    args["to"]   = Date.parse args["to"]
    codes  = args["code"] ? 
      [args["code"]] : read_codes
    reader =  @yahoo
    codes.each do |code|
      code = code[0..3]
      next if args["codefrom"] and args["codefrom"] > code 
      while not reader.read_stocks(code, args["from"] ,args["to"])
        sleep 60
      end
      stc_cnt  = 0 
      reader.stocks.each do |stock| 
        stc_cnt += stock.save ? 1 : 0
      end
      spt_cnt  = reader.splits.inject(0) {|s, split| s += split.save ? 1 : 0}
      puts "insert stocks #{code}: #{stc_cnt}/#{reader.stocks.length}"
      puts "insert splits #{code}: #{spt_cnt}/#{reader.splits.length}"
    end
  end

  def schedule
    codes  = Kabu::KDb.read_codes
    reader =  @yahoo

    codes.each do |code_market|
      code, market = code_market.split('-')
      company = Kabu::Company.find_by_code code
      if company and company.soks.length > 0
        from = company.soks.order(:date).last.date + 1
        to = Date.today
      else
        Kabu::Company.new(code: code, market: market).save
        from = Date.parse('20000101')
        to = Date.today
      end
      while not reader.read_stocks(code, from, to)
        sleep 60
      end
      stc_cnt  = 0 
      reader.stocks.each do |stock| 
        stc_cnt += stock.save ? 1 : 0
      end
      spt_cnt  = reader.splits.inject(0) {|s, split| s += split.save ? 1 : 0}
      puts "insert stocks #{code}: #{stc_cnt}/#{reader.stocks.length}"
      puts "insert splits #{code}: #{spt_cnt}/#{reader.splits.length}"
    end
  end

	def company
		count = 0
		codes = read_codes
		markets = read_markets
		codes.zip(markets).each do |code, market|
			com = Kabu::Company.new
			com.code = code
			com.market = market
			count += com.save ? 1 : 0
		end
		puts "#{count}/#{codes.count}"
	end
end

def read_codes
	file = File.expand_path('../../assets/codes_20190914.csv', __FILE__)
	ret = nil
	File.open(file).each_line do |line|
		ret = line.split(',').map do |code|
			code.chomp
		end
	end
	ret
end

def read_markets
	file = File.expand_path('../../assets/markets_20190914.csv', __FILE__)
	ret = nil
	File.open(file).each_line do |line|
		ret = line.split(',').map do |code|
			code.chomp
		end
	end
	ret
end


command = Command.new
case ARGV.shift
when "update"
  command.update(ARGV.getopts("",
                             "from:",
                             "to:",
                             "code:",
                             "codefrom:"))
when "schedule"
  command.schedule
when "company"
	command.company
else

end
