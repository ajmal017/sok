module Kabu
  class Soks < Array

    def self.parse(relations, *types)
      parse = types.inject(Soks.new) do |ret,type|
        ret << relations.inject(Soks.new) do |soks,r|
          soks << r.send(type)
        end
      end
      types.length == 1 ? parse[0] : parse
    end

    def self.adjust_length(*sokses)
      tmp = sokses.map do |soks|
        if soks.any? and soks[0].is_a? Soks
          soks.map{|sok| sok}
        else
          soks
        end
      end

      max = tmp.map {|soks| soks.length}.max
      sokses.map do |soks|
        if soks.any? and soks[0].is_a? Soks
          soks.map do |sok|
            Soks.new(max-sok.length,Float::NAN) + sok
          end
        else
          Soks.new(max-soks.length,Float::NAN) + soks
        end
      end
    end

    def split_up_and_down_sticks
      up_stick ,down_stick = Kabu::Soks.new, Kabu::Soks.new
      self.transpose.each do |o,h,l,c|
        if o >= c
          up_stick << Kabu::Soks[o,h,l,c]
          down_stick << Kabu::Soks.new(4,Float::NAN)
        else
          up_stick << Kabu::Soks.new(4,Float::NAN)
          down_stick << Kabu::Soks[o,h,l,c]
        end
      end
      [up_stick.transpose, down_stick.transpose]
    end

    def +(other)
      Soks[*super(other)]
    end

    def map
      Soks[*super]
    end

    def xtics(count: 10, visible: true)
      step = (length.to_f / count).to_i
      items = 1.step(length-1,step).map do |i|
        if visible 
          "\"#{self[i].strftime('%m/%d')}\" #{i}"
        else
          i
        end
      end
      "(#{items.join(',')})"
    end

    def ytics(count: 5)
      step = (length.to_f / count).to_i
      items = (step-1).step(length-1,step).map do |i|
        self[i]
      end
      "(#{items.join(',')})"
    end

    def yrange
      tmp = flatten.select{|v| v.integer? or  v.finite?}
      (tmp.min*0.98..tmp.max*1.02)
    end

    def x
      length.times.to_a
    end

    def y
      self
    end

    def bol(length, m = 1)
      aves, b_bands, u_bands, devs = 
        Soks.new, Soks.new, Soks.new, Soks.new
      self.each_cons(length) do |values|
        aves << values.sum / values.length
        dev = values.inject(0) {|s,v| s+=(v-aves[-1])**2}
        dev = Math.sqrt(dev/length)
        devs << dev
        b_bands << aves[-1] - m*dev
        u_bands << aves[-1] + m*dev
      end
      Soks[aves, b_bands, u_bands, devs]
    end

    def ave(length)
      results = Soks.new
      self.each_cons(length) do |values|
        results << values.sum / values.length
      end
      results
    end

    def transpose
      Soks[*super]
    end

  end

  class Array
    def sum
      self.inject(0) {|sum, a| sum += a}
    end
  end
end