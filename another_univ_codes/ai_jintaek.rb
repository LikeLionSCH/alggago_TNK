require "xmlrpc/server"
require "socket"
require "chipmunk"

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

class MyAlggago
    def mean(a, b)					return (a+b)/2 end
    def center(a,b)					return [(a[0]+b[0])/2,(a[1]+b[1])/2] end
    def angle(dx,dy)				return Math.atan(-1*dy/dx) end
    def vec(a,b)					return CP::Vec2.new(b[0]-a[0],-b[1]+a[1]) end
    def vec_angle(v_1,v_2)			return Math.atan(-1*(v_2[1]-v_1[1])/(v_2[0]-v_1[0])) end
    def distance(dx,dy)				return Math.sqrt(dx*dx+dy*dy) end
    def mag(a)						return Math.sqrt(a.dot(a)) end
    def distance_vector(y1,y2)		return Math.sqrt((y2[0]-y1[0])*(y2[0]-y1[0])+(y2[1]-y1[1])*(y2[1]-y1[1])) end
    
    def minOpponentPair(yours)
        dis = MAX_NUMBER; theta = 0
        yi = [0, 0]; yj = [0, 0]; yk = [0, 0]
        
        yours.each do |yours_i|
            yours.each do |yours_j|
                if (350-yours_i[0]).abs < (350-yours_j[0]).abs
                    y_distance = distance_vector(yours_i, yours_j)
                    if dis > y_distance
                        dis = y_distance
                        theta = vec_angle(yours_i, yours_j)
                        yi = yours_i; yj = yours_j
                    end
                end
            end
        end
        
        return dis, theta, yi, yj, yk
    end
    
    def breakMinPair(m1, theta, yi, yj)
        num = 0; index = 0
        x_comp = MAX_NUMBER
        y_comp = MAX_NUMBER
        x_comp_1 = MAX_NUMBER
        y_comp_1 = MAX_NUMBER
        power = 140
        ratio = Math.sin(theta)
        dist = MAX_NUMBER
        
        m1.each do |mine_1|
            if dist > distance_vector(center(yi, yj), mine_1)
                num = index
                
                dist = distance_vector(center(yi, yj), mine_1)
                if mine_1[1] > center(yi,yj)[1]
                    x_comp_1 = ((2-ratio)*yi[0] + (2+ratio)*yj[0])/4-mine_1[0]
                    y_comp_1 = ((2-ratio)*yi[1] + (2+ratio)*yj[1])/4-mine_1[1]
                    total = Math.sqrt(x_comp_1*x_comp_1+y_comp_1*y_comp_1)
                    x_comp = power*x_comp_1/total
                    y_comp = power*y_comp_1/total
                    
                    elsif mine_1[1] <= center(yi,yj)[1]
                    x_comp_1 = ((2+ratio)*yi[0] + (2-ratio)*yj[0])/4-mine_1[0]
                    y_comp_1 = ((2+ratio)*yi[1] + (2-ratio)*yj[1])/4-mine_1[1]
                    total = Math.sqrt(x_comp_1*x_comp_1+y_comp_1*y_comp_1)
                    x_comp = power*x_comp_1/total
                    y_comp = power*y_comp_1/total
                    
                end
            end
            index += 1
        end
        
        
        return num, x_comp, y_comp
    end
    
    def breakFarPair(m2,y2,y_1,y_2)
        d_1 = MAX_NUMBER
        d_2 = MAX_NUMBER
        num_1 = 0
        x_comp = 0
        y_comp = 0
        x_comp_1 = 0
        y_comp_1 = 0
        total = 0
        vel = 0
        num = 0
        index = 0
        dis = MAX_NUMBER
        logging = MAX_NUMBER
        power = 2
        alpha = 0
        
        m2.each do |mine_2|
            y2.each do |y_i|
                y2.each do |y_j|
                    vec_12 = vec(y_1,y_2)
                    vec_m1 = vec(mine_2,y_1)
                    vec_m2 = vec(mine_2,y_2)
                    vec_mc = vec(mine_2, center(y_1,y_2))
                    dot_vec_m1 = vec_12.dot(vec_m1)
                    dot_vec_m2 = vec_12.dot(vec_m2)
                    dot_vec_mc = vec_12.dot(vec_mc)
                    alpha = Math.asin(50/distance_vector(y_1,y_2))
                    
                    if dot_vec_m1 > 0
                        if dot_vec_m1 > mag(vec_m1)*mag(vec_12)*Math.cos(alpha)
                            if d_1 > distance_vector(mine_2,center(y_1,y_2))
                                num = index
                                
                                d_1 = distance_vector(mine_2,center(y_1,y_2))
                                x_comp = y_1[0]-mine_2[0]
                                y_comp = y_1[1]-mine_2[1]
                                logging = 1
                            end
                        else
                            num, x_comp, y_comp = breakCloseOne(m2, y2)
                        end
                        elsif dot_vec_m2 < 0
                        if dot_vec_m2 < mag(vec_m2)*mag(vec_12)*Math.cos(alpha)
                            if d_2 > distance_vector(mine_2,center(y_1,y_2))
                                num = index
                                
                                d_2 = distance_vector(mine_2,center(y_1,y_2))
                                x_comp = y_2[0]-mine_2[0]
                                y_comp = y_2[1]-mine_2[1]
                                logging = 2
                            end
                        else
                            num, x_comp, y_comp = breakCloseOne(m2, y2)
                        end
                        
                        else
                        num, x_comp, y_comp = breakCloseOne(m2, y2)
                        logging = 3
                    end
                    
                end
            end
            index += 1
        end
        return num, x_comp, y_comp, logging, d_1, alpha
    end
    
    def breakCloseOne(m5, y5)
        n = 0; i = 0
        min_length = MAX_NUMBER
        dx = MAX_NUMBER
        dy = MAX_NUMBER
        m5.each do |mine_l|
            y5.each do |y_k|
                current_distance = distance_vector(mine_l, y_k)
                if min_length > current_distance
                    n = i
                    min_length = current_distance
                    dx = y_k[0] - mine_l[0]
                    dy = y_k[1] - mine_l[1]
                end
            end
            i += 1
        end
        return n, dx, dy
    end
    
    def calculate(positions)
        @f = File.new("logg.txt","w")
        num = 0
        x_comp = MAX_NUMBER; y_comp = MAX_NUMBER
        logging = 0
        mine_p = positions[0];   yours_p = positions[1]
        min_y_distance = MAX_NUMBER
        min_theta = 0
        min_y_i = 0; min_y_j = 0
        current_distance = MAX_NUMBER
        min_length = MAX_NUMBER
        d_1 = 0
        alpha = 0
        unless yours_p.size == 1
            min_y_distance, min_theta, min_y_i, min_y_j = minOpponentPair(yours_p)
            if min_y_distance < 90

                num, x_comp, y_comp = breakMinPair(mine_p, min_theta, min_y_i, min_y_j) 
                @f.syswrite "1"
                @f.syswrite x_comp
                @f.syswrite y_comp
                elsif min_y_distance >= 90
                num, x_comp, y_comp, logging, d_1, alpha = breakFarPair(mine_p, yours_p, min_y_i, min_y_j)   
                @f.syswrite "2"
                @f.syswrite x_comp
                @f.syswrite y_comp
            end
            else
            num, x_comp, y_comp = breakCloseOne(mine_p, yours_p)
            @f.syswrite "3"
                @f.syswrite x_comp
                @f.syswrite y_comp
            logging = 4
        end
        @f.syswrite "5"
                @f.syswrite x_comp
                @f.syswrite y_comp
        message = positions.size
        stone_number = num
        stone_x_strength = x_comp*5
        stone_y_strength = y_comp*5
        
        return [stone_number, stone_x_strength, stone_y_strength, message]
    end
    
    def get_name
        " JINTAEK"
    end
end

s.add_handler("alggago", MyAlggago.new)
s.serve
