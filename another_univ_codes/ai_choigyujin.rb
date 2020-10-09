require "xmlrpc/server"
require "socket"
s = XMLRPC::Server.new(ARGV[0])

class M
  def calculate(p)
    my=p[0]
    your=p[1]
    cs=0
    ma=0
    xf=0
    yf=0
    my.each_with_index do|w,mi|
      your.each_with_index do|o,yi|
        e=0
        cl = dt(o,w)
        c=1
        e=eh(my,w,o)
        if e==0
          ml=0
          c=ac(your,w,o)
          if ma<c||(ma==1&&cl>ml&&c==ma)||(ma==c&&ml<cl)
            ml=cl
            ma=c
            cs=mi
            xf=o[0]-w[0]
            yf=o[1]-w[1]
          end
        end
      end
    end
    fxf = 700 * c(xf,yf)
    fyf = 700 * s(xf,yf)

    # 1:2 상황에서 상대의 돌을 빗겨침으로써 자살을 방지하는 알고리즘
    if my.length == 2 && your.length == 1 && fxf == 0 && fyf == 0
      a = Math.asin(50/dt(my[0],your[0]))
      fxf = 700 * Math.cos(dr(my[0],your[0])+a/1.5)
      fyf = 700 * Math.sin(dr(my[0],your[0])+a/1.5)
    end

    # 2:1 상황에서 내 돌이 상대의 돌 사이로 가게 하는 알고리즘
    if my.length == 1 && your.length == 2 && ma == 1
      k=50/dt(your[0],your[1])
      if dt(my[0],your[0]) > dt(my[0],your[1])
        x = (your[0][0]*(1-k)+your[1][0]*k) - my[0][0]
        y = (your[0][1]*(1-k)+your[1][1]*k) - my[0][1]
      else
        x = (your[1][0]*(1-k)+your[0][0]*k) - my[0][0]
        y = (your[1][1]*(1-k)+your[0][1]*k) - my[0][1]
      end
      l = Math.sqrt(x**2+y**2)
      v = Math.sqrt(2*l*90)
      fxf = v * c(x,y)
      fyf = v * s(x,y)
    end
    return[cs,fxf,fyf,0]
  end

  # 공격시 최대한 많은 돌을 치도록 하는 코드
  def ac(p,m,y)
    x=1
    a=y[1]-m[1]
    b=m[0]-y[0]
    cl=dt(y,m)
    c=-(a*m[0]+b*m[1])
    p.each do|yr|
      if yr!=y
        yl=dt(yr,y)
        l=ol(a,b,c,yr)
        d=dt(yr,m)
        if d>yl&&d>cl
          if l>=14&&l<40
            x+=1
          elsif l<14&&l>4
            x+=0.5
          elsif l>=40&&l<46
            x+=0.5
          elsif l <4
            x+=0.2
          elsif l>=46&&l<50
            x+=0.2
          end
        end
        if l<50&&d<cl&&cl>yl
          x=-10
        end
      end
    end
    return x
  end

  # 공격시 자살방지
  def eh(p,i,o)
    a=o[1]-i[1]
    b=i[0]-o[0]
    cl=dt(o,i)
    c=-(a*i[0]+b*i[1])
    e=0
    p.each do|w|
      if w!=i
        m=dt(w,i)
        y=dt(w,o)
        l=ol(a,b,c,w)
        if l<50
          if m>cl&&m>y
            e+=1
          elsif cl>m&&cl>y
            e+=1
          end
        end
      end
    end
    return e
  end

  def get_name
    "THOR AI"
  end


  # 점과 직선사이 거리
  def ol(a,b,c,pos)
    return (a*pos[0]+b*pos[1]+c).abs/Math.sqrt(a**2+b**2)
  end

  # 점과 점사이 거리
  def dt(my_pos,your_pos)
    return Math.sqrt((my_pos[0]-your_pos[0])**2+(my_pos[1]-your_pos[1])**2)
  end

  # 점과 점사이 방향
  def dr(my_pos,your_pos)
    return Math.atan2(your_pos[1]-my_pos[1],your_pos[0]-my_pos[0])
  end

  # sin
  def s(x,y)
    if x==0 && y==0
      return 0
    else
      return y/Math.sqrt(x**2+y**2)
    end
  end

  # cos값
  def c(x,y)
    if x==0 && y==0
      return 0
    else
      return x/Math.sqrt(x**2+y**2)
    end
  end

end
s.add_handler("alggago", M.new)
s.serve
