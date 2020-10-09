require "xmlrpc/server"
require "socket"

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

class MyAlggago
  def calculate(positions)

    #Codes here
    my_position = positions[0]
    your_position = positions[1]

    current_stone_number = 0
    index = 0
    min_length = MAX_NUMBER
    x_length = MAX_NUMBER
    y_length = MAX_NUMBER
	
	index = 0
	indexAd = 0
	indexIn = 0
	
	maxpoint = -MAX_NUMBER
	
	r = 25
	rightness = 0
	rightCnt = 0
	mratio = 0
	s = ""
	my_position.each do |my|
		your_position.each do |your|
		point = 0
			# 나와 상대의 각도
			rad = -Math.atan2(your[1] - my[1], your[0] - my[0])
			
			x_t = (your[0] - my[0]) * Math.cos(rad) - (your[1] - my[1]) * Math.sin(rad)
			y_t = (your[0] - my[0]) * Math.sin(rad) + (your[1] - my[1]) * Math.cos(rad)
			
			#s = s + x_t.to_s + y_t.to_s + "\n"
		
			indexIn = 0
			my_position.each do |mymem|
				
				if index == indexIn
					next
				end
				
				x = (mymem[0] - my[0])  * Math.cos(rad) - (mymem[1] - my[1]) * Math.sin(rad)
				y = (mymem[0] - my[0]) * Math.sin(rad) + (mymem[1] - my[1]) * Math.cos(rad)
				
				mag1 = (y_t + r) * (y_t + r) + x_t * x_t
				mag2 = (y_t - r) * (y_t - r) + x_t * x_t
				
				yy1 = (y * (y_t + r) / mag1)
				xx1 = (x * (x_t) / mag1)
				
				yy2 = (y * (y_t - r) / mag1)
				xx2 = (x * (x_t) / mag1)
					
				#s = s + "right " + r_t_up.to_s  + ' ' + r_up.to_s + ' ' +  r_t_down.to_s + ' ' +  r_down.to_s + "\n"
				# 앞에 있으면, 막히는게 없는지 막히면 -500
				if (Math.sqrt(x * x + y * y) < Math.sqrt(x_t * x_t + y_t * y_t))
					# 앞에 있다.
					if ((r * 3.5 > Math.sqrt(xx1 * xx1 + yy1 * yy1)) or (r * 3.5 > Math.sqrt(xx2 * xx2 + yy2 * yy2)))
						point = point - 250
					end
				# 뒤에 있으면, 오른쪽인지 왼쪽인지 뒤에 있으면, -30
				else
					# 왼쪽이다.
					if y > 0 and x.abs < r * 3
					# 오른쪽으로 향해야함 넘 오른쪽이면 버린다.
						rightness = rightness + 1
						point = point - 40
					# 오른쪽이다.
					elsif y > 0 and x.abs < r * 3
						rightness = rightness - 1
						point = point - 40
					end
					rightCnt = rightCnt + 1
					point = point - 100
				end
				indexIn = indexIn + 1
			end
			
			indexIn = 0
			your_position.each do |yourmem|
				if indexAd == indexIn
					next
				end
				x = (yourmem[0] - my[0])  * Math.cos(rad) - (yourmem[1] - my[1]) * Math.sin(rad)
				y = (yourmem[0] - my[0]) * Math.sin(rad) + (yourmem[1] - my[1]) * Math.cos(rad)
				
				# 앞에 있으면 무시
				# 뒤에 있으면, 오른쪽인지 왼쪽인지 뒤에 있으면, +10
				if (Math.sqrt(x * x + y * y) > Math.sqrt(x_t * x_t + y_t * y_t))
					# 왼쪽이다.
					if y > 0 and x.abs < r * 1.5 and y.abs < r * 3
					# 왼쪽으로 향해야함 너무 왼쪽이면 버린다.
						rightness = rightness - 1
						point = point + 20
					# 오른쪽이다.
					elsif y <= 0 and x.abs < r * 1.5 and y.abs < r * 3
						rightness = rightness + 1
						point = point + 20
					end
					
					if y.abs < r * 10
						point = point + 20
					end
					rightCnt = rightCnt + 1
				end
				indexIn = indexIn + 1
			end
			
			# 최적수인지 검사, 미세 방향 조정
			
			if rightCnt == 0
				ratio = 0
			else
				ratio = ( (rightness) / (rightCnt) * 1.0)
			end
			
			#s = s + "right " + rightness.to_s  + ' ' + rightCnt.to_s + ' ' +  point.to_s + "\n"
			if maxpoint <= point
			  #s = s + "right " + rightness.to_s  + ' ' + rightCnt.to_s + ' ' +  point.to_s + "\n"
			  r_ret = -Math.atan2(y_t + ratio * r, x_t)
			  current_stone_number = index
			  maxpoint = point
			  
			  x_length = (your[0]-my[0])*Math.cos(r_ret) - (your[1]-my[1])*Math.sin(r_ret);
			  y_length = (your[0]-my[0])*Math.sin(r_ret) + (your[1]-my[1])*Math.cos(r_ret);
			  
			  mratio = ratio
			end
			
			indexAd = indexAd + 1
		end
		index = index + 1
	end
	

    #Return values
    message = positions.size
    stone_number = current_stone_number
    stone_x_strength = x_length * 10 * (1-mratio.abs) + x_length * 3 * (mratio.abs)
    stone_y_strength = y_length * 10 * (1-mratio.abs) + y_length * 3 * (mratio.abs)
    return [stone_number, stone_x_strength, stone_y_strength, message]

    #Codes end
  end

  def get_name
    "Ball Crusher!!!"
  end
end

s.add_handler("alggago", MyAlggago.new)
s.serve
