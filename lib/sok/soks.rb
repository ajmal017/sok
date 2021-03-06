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

    def self.cut_off_tail(*sokses)
      tmp = []
      sokses.each do |soks|
        if soks.any? and soks[0].is_a? Soks
          soks.each{|sok| tmp << sok}
        else
          tmp << soks
        end
      end

      min = tmp.map {|soks| soks.length}.min
      sokses.map do |soks|
        if soks.any? and soks[0].is_a? Soks
          soks.map do |sok|
            sok[-min..-1]
          end
        else
          soks[-min..-1]
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
      step = 1 if step == 0
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
      min = tmp.min > 0 ? tmp.min*0.98 : tmp.min*1.02
      max = tmp.max > 0 ? tmp.max*1.02 : tmp.max*0.98
      (min..max)
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

    def cor(other, length)
      results = Soks.new
      self.zip(other).to_a.each_cons(length) do |values|
        x,y,xy = 0,0,0
        t, o = values.transpose
        xa = t.sum / t.length
        ya = t.sum / t.length
        values.each do |a,b|
          x += (a-xa) ** 2
          y += (b-ya) ** 2
          xy = (a-xa) * (b-ya)
        end
        results << xy / Math.sqrt(x) / Math.sqrt(y)
      end
      results
    end

    def rsi(length)
      results = Soks.new
      self.each_cons(length) do |values|
        plus = 0
        minus = 0
        values.each_cons(2) do |v|
          diff = v.last - v.first
          if diff > 0
            plus += diff
          else
            minus += diff.abs
          end
        end
        results << plus / (minus + plus) * 100
      end
      results
    end

    def diff(length=2)
      results = Soks.new
      self.each_cons(length) do |values|
        results << values.last - values.first
      end
      results
    end

    def abs
      results = Soks.new
      self.each do |value|
        results << value.abs
      end
      results
    end

    def ave(length)
      results = Soks.new
      self.each_cons(length) do |values|
        results << values.sum / values.length
      end
      results
    end

    def dev(length)
      results = Soks.new
      self.each_cons(length) do |values|
        ave = values.sum / values.length
        dev = values.inject(0) {|s,v| s+=(v-ave)**2}
        results << Math.sqrt(dev/length)
      end
      results
    end

    def vol(length, ave)
      results = Soks.new
      self.reverse.each_cons(length).to_a.each_with_index do |values, i|
        next if not ave.length - values.length - i >= 0
        sum = 0
        values.each_with_index do |value, j|
          sum += (value - ave[ave.length-1-i-j])** 2
        end
        results << Math.sqrt(sum/length)
      end
      results.reverse
    end

    def ravi(s_length, l_length)
      l_ave = self.ave(l_length)
      s_ave = self.ave(s_length)[-l_ave.length..-1]
      s_ave.zip(l_ave).map do |s, l|
        (s-l).abs/l*100
      end
    end

    def high(length)
      results = Soks.new
      self.each_cons(length) do |values|
        results << values.inject(0) {|h,v| h=[h,v.high].max}
      end
      results
    end

    def low(length)
      results = Soks.new
      self.each_cons(length) do |values|
        results << values.inject(Float::MAX) {|l,v| l=[l,v.low].min}
      end
      results
    end

    def stc(n, value = nil)
      results = Soks.new
      self.each_cons(n) do |soks|
        max, min = Soks[*soks].high(soks.length)[-1], Soks[*soks].low(soks.length)[-1]
        if value
          results << (value - min).to_f / (max - min ) * 100
        else
          results << (soks.last.close - min).to_f / (max - min ) * 100
        end
      end
      results
    end

    def vidya(n,s_len,l_len)
      results = Soks[self[0]]
      alpha = 2.0 / (n + 1)
      self[1..-1].each_cons(l_len+1) do |values|
        l_dev = Soks[*values].log.dev(l_len)[-1]
        s_dev = Soks[*values[-s_len-1..-1]].log.dev(s_len)[-1]
        vi = s_dev / l_dev
        vi = 1 if vi > 1 
        results << results.last + alpha * vi * (values[-1] - results.last)
      end
      results
    end

    def kama(n,s_len,l_len)
      results = [self[0]]
      kama = self[0]
      self[1..-1].each_cons(n+1) do |values|
        er = (values[-1] - values[-n]) / Soks[*values].diff.abs.sum
        er = 0 if not er.to_f.finite?
        alpha = (er*(2.0/(s_len+1) - 2.0/(l_len+1)) + 2.0/(l_len+1)) ** 2
        kama = kama + alpha * (values[-1] - kama)
        results << kama
      end
      Soks[*results]
    end

    def exp_ave(a)
      results = Soks[self[0]]
      self[1..-1].each do |value|
        results << results.last + a * ( value - results.last)
      end
      results
    end

    def dx(length)
      result = []
      self.each_cons(length+1) do |values|
        pdm, mdm, tr = [], [], []
        values.each_cons(2) do |vs|
          pdm << vs[-1].high - vs[-2].high
          mdm << vs[-2].low - vs[-1].low
          if (pdm[-1] < 0 and mdm[-1] < 0) or pdm == mdm
            pdm[-1], mdm[-1] = 0, 0
          elsif pdm[-1] > mdm[-1]
            mdm[-1] = 0
          elsif pdm[-1] < mdm[-1]
            pdm[-1] = 0
          end
          tr << [vs[-1].high - vs[-1].low, vs[-1].high - vs[-2].close, vs[-2].close - vs[-1].low].max
        end
        ts, ps, ms = tr.sum, pdm.sum, mdm.sum
        pdi = ps / ts * 100
        mdi = ms / ts * 100
        result << (pdi - mdi).abs / (pdi + mdi) * 100
      end
      Soks[*result]
    end

    def adx(n,m)
      result = []
      self.dx(n).each_cons(m) do |dxs|
        result << dxs.sum / length
      end
      Soks[*result]
    end

    def cumu
      sum = 0
      self.map do |value|
        sum += value.finite? ? value : 0
      end
    end

    def log
      results = Soks.new
      self.each_cons(2) do |values|
        results << Math.log(values[1] / values[0])
      end
      results
    end

    def transpose
      Soks[*super]
    end

    def zip(*other)
      Soks[*super(*other)]
    end

  end

  class Array
    def sum
      self.inject(0) {|sum, a| sum += a}
    end
  end
end
