require "xmlrpc/server"
require "socket"

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

class MyAlggago
=begin
 
  def get_incline(m,b,n,c)
	r=50
	ans1 = 2 * Math.sqrt(b * b * r * r - 2 * b * c * r * r + c* c * r * r +m * m * r * r - 2*m*n*r*r +n*n*r*r-4*r*r*r*r)
	ans2 = b*m-b*n-c*m+c*n
	ans3 = m*m - 2*m*n + n*n - 4 * r*r
	return [(-ans1+ans2)/ans3, (ans1+ans2)/ans3]
  end

  
  def get_reduced_velocity original_velocity, original_velocity_length
	BOARD_FRICTION = 1.50
    if original_velocity.abs <= BOARD_FRICTION * (original_velocity.abs / original_velocity_length)
      return 0 
    else 
      return (original_velocity.abs / original_velocity) * 
                (original_velocity.abs - BOARD_FRICTION * (original_velocity.abs / original_velocity_length))
    end
  end  

  def get_distance(v,v_length)
	n1 = floor(v.abs/1.5*(v.abs/v_length) + 3
	return (v +(n1 - 1)*1.5 / 2) * n1
  end
  

  
  def sim_go(vx,vy,positions,team,n)
	x = positions[team][n][0]
	y = positions[team][n][1]
	v_length = Math.sqrt(vx * vx + vy * vy)
	while vx + vy != 0
		for i in 0..1
			for j in 0..positions[i].length
				if i == team
					if j == n
						break
					end
				end
				temp_x = positions[i][j][0]
				temp_y = positions[i][j][1]
				temp_distance = Math.sqrt((x - temp_x) * (x - temp_x) + (y - temp_y) * (y - temp_y))
				if temp_distance <= 625
					
		x = x + vx
		y = y + vy
		vy = get_reduced_velocity(vy, v_length)
		vx = get_reduced_velocity(vx, v_length)
	return [x,y]
	end
		
  def calculate(positions)
	
	
	###Pre - Codes here
	
	my_position = positions[0]
	your_position = positions[1]
	
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
		
		tan_distance = Math.sqrt(current_distance * current_distance - 2500)
		incline_mid = (my[1] - your[1]) / (my[0] - your[0])
		incline_edge = (get_incline(my[0],my[1],your[0],your[1]))
		incline1 = Math.atan2(incline_edge[0])
		incline2 = Math.atan2(incline_edge[1])
		incline_d= (incline2-incline1)/200
		incline = incline1
		while True
			if incline>=incline2
				break
			end
			incline = incline + incline_d
			
			s_index = 0
			while True
				s_index=s_index+5
				get_distance(s_index)
			power = 
			while True
				
		Math.atan2(incline_edge[0])
		
=end	
		
	
	
  def calculate(positions)
	
    #Codes here
    my_position = positions[0]
    your_position = positions[1]

    current_stone_number = 0
	csn = 0
    index = 0
	index2 = 0
    min_length = MAX_NUMBER
    x_length = MAX_NUMBER
    y_length = MAX_NUMBER
	x_lengthe = MAX_NUMBER
	y_lengthe = MAX_NUMBER
	min_e_distance = MAX_NUMBER
	min_ee_distance = MAX_NUMBER
	
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
	

    your_position.each do |your1|
	    your_position.each do |your2|

			if your1[0] == your2[0]
				if your1[1] == your2[1]
					break
				end
			end
			
			e_distance = Math.sqrt((your2[0] - your1[0]) * (your2[0] - your1[0]) + (your2[1] - your1[1]) * (your2[1] - your1[1]) )

			if min_e_distance > e_distance
			  min_e_distance = e_distance
			end
		
		
		if min_e_distance < 90
		  x_cordin = (your1[0] + your2[0]) / 2
		  y_cordin = (your1[1] + your2[1]) / 2
		  my_position.each do |my2|
		    ee_distance = Math.sqrt((x_cordin - my2[0]) * (x_cordin - my2[0]) + ((y_cordin - my2[1]) * (y_cordin - my2[1])))
			if min_ee_distance > ee_distance
			  min_ee_distance = ee_distance
			  x_lengthe = x_cordin - my2[0]
			  y_lengthe = y_cordin - my2[1]
			  csn = index2
			end
			index2 = index2 + 1
		  end
		  
		  length_a = Math.sqrt((my_position[csn][0] - your1[0]) * (my_position[csn][0] - your1[0]) + (my_position[csn][1] - your1[1]) * (my_position[csn][1] - your1[1]))
		  length_b = Math.sqrt((my_position[csn][0] - your2[0]) * (my_position[csn][0] - your2[0]) + (my_position[csn][1] - your2[1]) * (my_position[csn][1] - your2[1]))
		  d_length = (length_a - length_b).abs
		  guess_length = Math.sqrt(min_e_distance * min_e_distance + d_length * d_length)
		  
		  if guess_length <= 59
			if length_a<=length_b
			  x_lengthe = x_lengthe - x_cordin + your1[0]
			  y_lengthe = y_lengthe - y_cordin + your1[1]
			end
			if length_a> length_b
			  x_lengthe = x_lengthe - x_cordin + your2[0]
			  y_lengthe = y_lengthe - y_cordin + your2[1]
			end
		  end
		  return [csn,x_lengthe * 100, y_lengthe * 100, 0720 ]
		end
		end
	end

	
	
    #Return values
    message = 20
    stone_number = current_stone_number
    stone_x_strength = x_length * 10
    stone_y_strength = y_length * 10
    return [stone_number, stone_x_strength, stone_y_strength, message]

    #Codes end
  end

  def get_name
    "INFACT5NECK"
  end
end

s.add_handler("alggago", MyAlggago.new)
s.serve
