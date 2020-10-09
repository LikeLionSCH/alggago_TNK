require "xmlrpc/server"
require "socket"

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000






class MyAlggago
  def calculate(positions)
    coeff = 0.70

    #Codes here
    my_position = positions[0]
    your_position = positions[1]
    myN = my_position.length
    yourN = your_position.length
    message = "not"
    bullet = 0
    target = [0,0]

    bestcandiS = Array.new()
    secondcandiS = Array.new()
    firstcandiS = Array.new()
    def aim(me, target)
      result = [(target[0]-me[0])*100000,(target[1]-me[1])*100000]
      return result
    end

    def around(target, seta, r)
      result = [target[0]+r*Math.cos(seta*Math::PI), target[1]+r*Math.sin(seta*Math::PI)]
      return result
    end

    def line2point(line,target)
      a, b, c = line[0], line[1], line[2]
      x, y = target[0], target[1]
      divider = Math.sqrt(a*a + b*b)
      divided = a*x + b*y + c
      result = divided.abs/divider
      return result
    end

    def linerate(point1, point2)
      x1, y1 = point1[0], point1[1]
      x2, y2 = point2[0], point2[1]
      a = y2-y1
      b = -(x2-x1)
      c = -x1*(y2-y1)+y1*(x2-x1)
      return [a,b,c]
    end

    def perpenlinerate(point1,point2,start)
      x1, y1 = point1[0], point1[1]
      x2, y2 = point2[0], point2[1]
      x, y = start[0], start[1]
      a = -(x2-x1)
      b = -(y2-y1)
      c = y*(y2-y1)+x*(x2-x1)
      return [a,b,c]
    end

    def substi(line,point)
      a, b, c = line[0], line[1], line[2]
      x, y = point[0], point[1]
      return a*x+b*y+c
    end

    def dist(point1, point2)
      x1, y1 = point1[0], point1[1]
      x2, y2 = point2[0], point2[1]
      return Math.sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1))
    end

    def whatbetween(point1,point2,candidateS)
      x1, y1 = point1[0], point1[1]
      x2, y2 = point2[0], point2[1]
      line = linerate(point1,point2)
      perline1 = perpenlinerate(point1,point2,point1)
      perline2 = perpenlinerate(point1,point2,point2)
      canN = candidateS.length
      result = Array.new()
      for c in 0...canN
        target = candidateS[c]
        if line2point(line,target) < 52 and substi(perline1,target) * substi(perline2,target) < 0
          result.push(c)
        end
      end
      return result
    end

    def whatafter2(point1,point2,candidateS)
      x1, y1 = point1[0], point1[1]
      x2, y2 = point2[0], point2[1]
      line = linerate(point1,point2)
      perline1 = perpenlinerate(point1,point2,point1)
      perline2 = perpenlinerate(point1,point2,point2)
      canN = candidateS.length
      result = Array.new()
      for c in 0...canN
        target = candidateS[c]
        if target[0] == x1 and target[1] == y1
          next
        end
        if target[0] == x2 and target[1] == y2
          next
        end
        if line2point(line,candidateS[c]) < 30 and dist(point1, c) > dist(point2, c)
          result.push(c)
        end
      end
      return result
    end




    for yn1 in 0...yourN
      for yn2 in yn1+1...yourN
        b = your_position[yn1]
        c = your_position[yn2]
        if dist(b,c) < 75
          midpoint = [(b[0]+c[0])/2,(b[1]+c[1])/2]
          perline = perpenlinerate(b,c,midpoint)
          if perline[1] == 0
            seta = 0.5*Math::PI
          else
            seta = Math.atan(-perline[0]/perline[1])
          end
          temp = Array.new(0)
          for n in -1000..0
            move = n/20.0
            h = [midpoint[0]+move*Math.cos(seta),midpoint[1]+move*Math.sin(seta)]
            score = (50-dist(h,b)).abs
            temp.push([score,h])
          end
          nh = temp.min[1]
          temp = Array.new(0)
          for n in 0..1000
            move = n/20.0
            h = [midpoint[0]+move*Math.cos(seta),midpoint[1]+move*Math.sin(seta)]
            score = (50-dist(h,b)).abs
            temp.push([score,h])
          end
          ph = temp.min[1]
          hS = [ph, nh]
          for h in hS
            line = linerate(h,midpoint)
            for an in 0...myN
              a = my_position[an]
              if line2point(line,a) < 100
                if whatbetween(a,h,my_position).length == 0 and whatbetween(a,h,your_position).length == 0
                  score = whatafter2(h,b,your_position).length + whatafter2(h,c,your_position).length
                  firstcandiS.push([score,an,h])
                end
              end
            end
          end
        end
      end
    end




    if 1 == 1
      for mn in 0...myN
        for yn1 in 0...yourN
          for yn2 in 0...yourN
            if yn1 == yn2
              next
            end
            a = my_position[mn]
            b = your_position[yn1]
            c = your_position[yn2]
            if whatbetween(a,b,my_position).length + whatbetween(a,b,your_position).length > 0
              next
            end
            ac = dist(a,c)
            bc = dist(b,c)
            if ac > bc# and 2 == 3
            #if 2== 3
              for n in 0..3600
                angle = 2.0*n/3600
                h = around(b,angle,50)
                ah = dist(a,h)
                bh = dist(b,h)
                ab = dist(a,b)
                ch = dist(c,h)
                cosform = (bh*bh+ah*ah-ab*ab)/(2*ah*bh)
                if cosform < -1 or cosform > 1
                  next
                end
                angle_bha = Math.acos(cosform)
                if angle_bha < 3.14/1.4 or angle_bha > 3.14*4/5
                  next
                end
                if ab < ah
                  next
                end
                if whatbetween(a,h,my_position).length + whatbetween(a,h,your_position).length > 0
                  next
                end
                if whatbetween(c,h,my_position).length > 0
                  next
                end
                line = perpenlinerate(b,h,h)
                line2 = linerate(b,h)
                if (line[0]*a[0]+line[1]*a[1]+line[2])*(line[0]*c[0]+line[1]*c[1]+line[2])>0
                  next
                end
                if (line2[0]*a[0]+line2[1]*a[1]+line2[2])*(line2[0]*c[0]+line2[1]*c[1]+line2[2])>0
                  next
                end
                per = line2point(line,a)
                cal = line2point(line2,a)
                angle1 = Math.atan((per*(1-coeff)/2)/cal)
                per2 = line2point(line,c)
                cal2 = line2point(line2,c)
                angle2 = Math.atan((per2)/cal2)
                if (angle1-angle2).abs < 0.001
                  score = 0
                  if whatafter2(h,b,your_position).length > 0
                    score += 10
                  end
                  if score >= 1
                    bestcandiS.push([(angle1-angle2).abs,mn,h,angle1,angle2])
                  else
                    secondcandiS.push([(angle1-angle2).abs,mn,h,angle1,angle2])
                  end
                end
              end
            end
          end
        end
      end
    end

    finalcani = Array.new()


    for an in 0...myN
      for bn in 0...yourN
        a = my_position[an]
        b = your_position[bn]
        if whatbetween(a,b,my_position).length + whatbetween(a,b,your_position).length == 0
          if whatafter2(a,b,my_position).length == 0
            score = whatafter2(a,b,your_position).length
            finalcani.push([score,an,b])
          end
        end
      end
    end



    if firstcandiS.length > 0
      line = firstcandiS.min
      bullet = line[1]
      target = line[2]
      message = ["first"]
    else
      if bestcandiS.length > 0
        line = bestcandiS.min
        bullet = line[1]
        target = line[2]
        message = ["best",line[3],line[4]]
      else
        if secondcandiS.length >0
          line = secondcandiS.min
          bullet = line[1]
          target = line[2]
          message = ["second",line[3],line[4]]
        else
          if finalcani.length >0
            line = finalcani.max
            bullet = line[1]
            target = line[2]
            message = ["final"]
          else
            current_stone_number = 0
            index = 0
            min_length = MAX_NUMBER
            x_length = MAX_NUMBER
            y_length = MAX_NUMBER

            my_position.each do |my|
              your_position.each do |your|

                x_distance = (my[0] - your[0]).abs
                y_distance = (my[1] - your[1]).abs
                
                current_distance = Math.sqrt(x_distance * x_distance + y_distance * y_distance)

                if min_length > current_distance
                  current_stone_number = index
                  min_length = current_distance
                  x_length = your[0] - my[0]
                  y_length = your[1] - my[1]
                end
              end
              index = index + 1
            end

            #Return values
            bullet = current_stone_number
            xshot = x_length * 5
            yshot = y_length * 5
            message = 'backup'
          end
        end
      end
    end

    if message != 'backup'
      result = aim(my_position[bullet],target)
      xshot, yshot = result[0], result[1]
    end





    


    return [bullet, xshot, yshot, message]

    #Codes end
  end

  def get_name
    "FlyLikeA_Pigeon"
  end
end

s.add_handler("alggago", MyAlggago.new)
s.serve
