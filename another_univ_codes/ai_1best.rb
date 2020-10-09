require "xmlrpc/server"
require "socket"
require "matrix"
require "chipmunk"



WIDTH, HEIGHT = 1000, 700
TICK = 1.0/60.0
NUM_STONES = 7
PLAYER_COLOR = ["black", "white"]
STONE_DIAMETER = 50
RESTITUTION = 0.9
BOARD_FRICTION = 1.50
STONE_FRICTION = 0.5
ROTATIONAL_FRICTION = 0.04
FINGER_POWER = 3
UI_PIVOT = 100
MAX_POWER = 700.0

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000.0

class Stone
    attr_reader :body, :shape
    attr_accessor :should_delete
    def initialize(position_x, position_y)
        @should_delete = false
        @body = CP::Body.new(1, CP::moment_for_circle(1.0, 0, 1, CP::Vec2.new(0, 0)))
        
        
        @body.p = CP::Vec2.new(position_x, position_y)
        #@body.v = CP::Vec2.new(rand(HEIGHT)-HEIGHT/2, rand(HEIGHT)-HEIGHT/2)
        
        @shape = CP::Shape::Circle.new(body, STONE_DIAMETER/2.0, CP::Vec2.new(0, 0))
        @shape.e = RESTITUTION
        @shape.u = STONE_FRICTION
        
    end
    
    def update
        #update speed
        new_vel_x, new_vel_y = 0.0, 0.0
        if @body.v.x != 0 or @body.v.y != 0
            new_vel_x = get_reduced_velocity(@body.v.x, @body.v.length)
            new_vel_y = get_reduced_velocity(@body.v.y, @body.v.length)
        end
        @body.v = CP::Vec2.new(new_vel_x, new_vel_y)
        
        #update speed of angle
        new_rotational_v = 0
        new_rotational_v = get_reduced_rotational_velocity @body.w if @body.w != 0
        @body.w = new_rotational_v
    end
    
    private
    def get_reduced_velocity original_velocity, original_velocity_length
        if original_velocity.abs <= BOARD_FRICTION * (original_velocity.abs / original_velocity_length)
            return 0
            else
            return (original_velocity.abs / original_velocity) *
            (original_velocity.abs - BOARD_FRICTION * (original_velocity.abs / original_velocity_length))
        end
    end
    
    private
    def get_reduced_rotational_velocity velocity
        if velocity.abs <= ROTATIONAL_FRICTION
            return 0
            else
            return (velocity.abs / velocity) * (velocity.abs - ROTATIONAL_FRICTION)
        end
    end
end




# �� �뚯쓣 �뉖뒗 吏곸꽑�� 留뚮뱾怨�, 洹� 吏곸꽑 �꾩뿉 �곕━ �뚯씠 �녿뒗吏 �먮떒�섎뒗 肄붾뱶 諛섑솚媛�(�댁씤�깆뒪, �곷� �몃뜳��, �곹깭)
#吏곸꽑�� 諛⑹젙�� ax+by+1 = 0 �� ��, 吏곸꽑怨� ��(x1,y1)�ъ씠�� 嫄곕━�� abs(a*x1+b*y1+1)/Math.sqrt(a*a+b*b)
# 留뚯빟 紐⑤뱺 議곌굔�� 留뚯”�쒕떎硫� �곹깭瑜� 1濡� 留뚮뱾怨�, �곹깭 1�� �대떦�섎㈃ 洹몄쭅�좎쓣 留뚮뱶�� �대룎濡� �곷� �뚯쓣 移쒕떎.r


class MyAlggago
    def find_index_alpha(my_index,your_index,state,final_stone_index,alpha_array,countK)
        alpha = 0
        
        c = 0
        d = 0
        
        min_distance = 16000.0
        mimin_distance = 16000.0
        if state == 0
            x_distance = (@my_position[my_index][0] - @your_position[your_index][0]).abs
            x1= @my_position[my_index][0]
            y1= @my_position[my_index][1]
            y_distance = (@my_position[my_index][1] - @your_position[your_index][1]).abs
            x2= @your_position[your_index][0]
            y2= @your_position[your_index][1]
            else
            x_distance = (@your_position[my_index][0] - @your_position[your_index][0]).abs
            x1= @your_position[my_index][0]
            y1= @your_position[my_index][1]
            y_distance = (@your_position[my_index][1] - @your_position[your_index][1]).abs
            x2= @your_position[your_index][0]
            y2= @your_position[your_index][1]
        end
        current_distance = Math.sqrt(x_distance * x_distance + y_distance * y_distance)
        if current_distance < 50.0
            
            current_distance = 50.1
        end
        max_theta = Math.acos(50.0/current_distance)  # �묓븯�� 理쒕�媛곸뿉�� 10�꾨� 類 媛�
        
        #留욌뒗 �뚯쓣 �먯젏�쇰줈 �섍퀬, �먮룎�� �뉖뒗 吏곸꽑�� x異뺤쑝濡� �섏��� ��, �대룎, 留욌뒗 �뚯씠 媛� �� �덈뒗 踰붿쐞
        
        index = -1
        final_index = 0
        fifinal_index = 0
        count=0
        @your_position.each do |your|
            
            catch :done do
                if @your_position.size > index +1
                    index += 1
                end
                final_stone_index.each do |i|
                    if index == i
                        throw :done
                    end
                end
                if your != [x2,y2]
                    vector_12 = Vector[x2-x1,y2-y1] #�대룎 -> �곷��� 踰≫꽣
                    vector_23 = Vector[your[0]-x2,your[1]-y2] # �곷��� -> �ㅻⅨ �곷��� 踰≫꽣
                    vector_beta1 = Vector[your[0]+56.0,your[1]] # �� �뚯쓽 �곷��뚭낵 媛�� 媛源뚯슫 異쒕컻吏�� 源뚯��� �ㅻⅨ �곷��� 踰≫꽣
                    vector_beta2 = Vector[your[0]+80.0,your[1]] # �� �뚯쓽 �곷��뚭낵 媛�� 癒� 異쒕컻吏�� 源뚯��� �ㅻⅨ �곷��� 踰≫꽣
                    
                    dot_12_23 = vector_12.dot vector_23
                    alpha_tmp = Math.acos(dot_12_23/(vector_12.r*vector_23.r))
                    
                    
                    
                    if alpha_tmp <max_theta and dot_12_23 >0 and min_distance > vector_23.r
                        min_distance = vector_23.r
                        alpha = alpha_tmp
                        final_index = index
                        c = 1
                    end
                    
                    if vector_beta1[1]/vector_beta1[0] > 0 and vector_beta1[1]/vector_beta1[0] < 1.44 and vector_beta2[1]/vector_beta2[0] > 0.77 and dot_12_23 > 0 and mimin_distance > vector_23.r
                        fifinal_index = index
                        d = 1
                        mimin_distance = vector_23.r
                        elsif  vector_beta1[1]/vector_beta1[0] < 0 and vector_beta1[1]/vector_beta1[0] > -1.44 and vector_beta2[1]/vector_beta2[0] < -0.77 and dot_12_23 > 0 and mimin_distance > vector_23.r
                        fifinal_index = index
                        d = 1
                        mimin_distance = vector_23.r
                    end
                    
                    
                    count += 1
                    
                    if c == 0 and d == 0
                        count -= 1
                    end
                    
                end
                
            end
            
        end
        final_stone_index << your_index
        alpha_array<< alpha
        
        if count == 0
            return alpha_array,final_stone_index,countK
        end
        if c == 1 and d == 1
            countK += 1
            @f.syswrite "11 \n"
            alpha_array,final_stone_index,countK= find_index_alpha(your_index,fifinal_index,1,final_stone_index,alpha_array,countK)
            
            
            elsif c == 1 and d == 0
            @f.syswrite "10 \n"
            alpha_array,final_stone_index,countK= find_index_alpha(your_index,final_index,1,final_stone_index,alpha_array,countK)
            
            elsif c == 0 and d == 1
            @f.syswrite "01 \n"
            countK += 1
            alpha_array,final_stone_index,countK= find_index_alpha(your_index,fifinal_index,1,final_stone_index,alpha_array,countK)
            
        end
        
        return alpha_array,final_stone_index,countK
        
        
    end
    ###############################################################
    
    ###############################################################
    def no_my_stone
        min_my_distance = [MAX_NUMBER,MAX_NUMBER]
        min_your_distance = [MAX_NUMBER,MAX_NUMBER]
        available_stone_index = nil
        available_stone_index = Array.new()
        a = nil
        b = nil
        a=Array.new()
        b=Array.new()
        my_index = 0
        your_index = 0
        index = 0
        @state = 0
        @my_position.each do |my|
            @your_position.each do |your|
                aa = (my[1]-your[1])/(my[0]*your[1]-my[1]*your[0])
                bb = (your[0]-my[0])/(my[0]*your[1]-my[1]*your[0])
                s=Math.sqrt((my[0]-your[0])*(my[0]-your[0])+(my[1]-your[1])*(my[1]-your[1]))#�ъ씠 嫄곕━
                #�꾩そ 吏곸꽑�� 諛⑹젙��
                alpha=Math.tan(Math.atan((-aa/bb)+Math.asin(50.0/s)))
                beta=my[1]-alpha*my[0]
                
                a[0]=alpha/beta
                b[0]=-1.0/beta
                
                #�꾨옒履� 吏곸꽑�� 諛⑹젙��
                alpha=Math.tan(Math.atan((-aa/bb)-Math.asin(50.0/s)))
                beta=my[1]-alpha*my[0]
                
                a[1]=alpha/beta
                b[1]=-1.0/beta
                
                [0,1].each do |i|
                    
                    @my_position.each do |my2|
                        #�섏쓽 �ㅻⅨ �뚭낵 �곷��� �ъ씠�� 嫄곕━媛 �먮옒 �뚭낵�� 嫄곕━蹂대떎 媛源뚯슫 �뚮뱾 以� 理쒖냼 distance瑜� 援ы븳��.
                        if my2 != my
                            my_x_distance1 = (my[0] - your[0]).abs
                            my_y_distance1 = (my[1] - your[1]).abs
                            my_x_distance2 = (my2[0] - your[0]).abs
                            my_y_distance2 = (my2[1] - your[1]).abs
                            my_current_distance1 = Math.sqrt(my_x_distance1 * my_x_distance1 + my_y_distance1 * my_y_distance1)
                            my_current_distance2 = Math.sqrt(my_x_distance2 * my_x_distance2 + my_y_distance2 * my_y_distance2)
                            distance_my = ((a[i]*my2[0]+b[i]*my2[1]+1)/Math.sqrt(a[i]*a[i]+b[i]*b[i])).abs
                            if min_my_distance[i] > distance_my and my_current_distance1 > my_current_distance2
                                min_my_distance[i] = distance_my
                            end
                        end
                    end
                    @your_position.each do |your2|
                        if your2 != your
                            distance_your = ((a[i]*your2[0]+b[i]*your2[1]+1)/Math.sqrt(a[i]*a[i]+b[i]*b[i])).abs
                            your_x_distance1 = (my[0] - your[0]).abs
                            your_y_distance1 = (my[1] - your[1]).abs
                            your_x_distance2 = (my[0] - your2[0]).abs
                            your_y_distance2 = (my[1] - your2[1]).abs
                            your_current_distance1 = Math.sqrt(your_x_distance1 * your_x_distance1 + your_y_distance1 * your_y_distance1)
                            your_current_distance2 = Math.sqrt(your_x_distance2 * your_x_distance2 + your_y_distance2 * your_y_distance2)
                            #�곷� �ㅻⅨ �뚯쓽 嫄곕━媛 湲곗〈 �뚯쓽 嫄곕━蹂대떎 媛源뚯슱 �� 理쒖냼 distance瑜� 援ы븳��.
                            if min_your_distance[i] > distance_your and your_current_distance1 > your_current_distance2
                                min_your_distance[i] = distance_your
                            end
                        end
                    end
                end#0,1
                #�곷� �ㅻⅨ ��, �� �뚯쓽 理쒖냼 嫄곕━媛 �뚯쓽 吏由꾨낫�� �� ��, 吏곸꽑�� �욎뿉 媛由щ뒗 寃껋씠 �녿떎怨� �앷컖�섍퀬, �댁뿉 �대떦�섎뒗 �몃뜳�� �먭컻瑜� 諛섑솚�쒕떎.
                if min_my_distance[0] > 50 and min_your_distance[0] > 50 and  min_my_distance[1] > 50 and min_your_distance[1] > 50
                    @state = 1
                    available_stone_index[index] = [my_index,your_index]
                    min_my_distance = [MAX_NUMBER,MAX_NUMBER]
                    min_your_distance = [MAX_NUMBER,MAX_NUMBER]
                    index += 1
                    
                end
                
                
                min_my_distance = [MAX_NUMBER,MAX_NUMBER]
                min_your_distance = [MAX_NUMBER,MAX_NUMBER]
                your_index += 1
                
            end
            your_index = 0
            my_index += 1
        end
        
        return available_stone_index
    end
    #########################################################
    def find_count(stone_index)
        theta = 0 #留욌뒗 �뚯쓽 媛�
        alpha_tmp = 0
        alpha_array = nil
        final_stone_index=nil
        alpha_list=nil
        final_index_list=nil
        countK =nil
        alpha_array = Array.new()
        final_stone_index=Array.new()
        alpha_list=Array.new()
        final_index_list=Array.new()
        countK = Array.new()
        i = 0
        
        stone_index.each do |index|
            alpha_array = Array.new()
            final_stone_index=Array.new()
            alpha_list[i],final_index_list[i], countK[i]= find_index_alpha(index[0],index[1],0,final_stone_index,alpha_array,0)
            alpha_array = nil
            final_stone_index= nil
            i +=1
        end
        return alpha_list, final_index_list,countK
    end
    
    
    #�ㅽ뻾 �섎뒗 肄붾뱶
    ###################################################################
    
    
    def determining_route(final_index_list,countK)
        max_size = 0
        index = 0
        optimal_index = 0
        
        max_count = 0
        k = 0
        final_index_list.each do |final_index|
            tmp_size = final_index.size
            if tmp_size > max_size
                max_size = tmp_size
                optimal_index = index
            end
            index += 1
        end
        i  = 0
=begin
        final_index_list.each do |final_index|
            tmp_size = final_index.size
            if tmp_size == max_size
                if countK[i] > max_count
                    max_count = countK[i]
                    optimal_index = i
                end
            end
            i+= 1
        end
=end
        return optimal_index
        
        
    end
    ###############################################################
    def get_distance(first_index,second_index,state)
        if state == 0 # �곷��� �먭컻 嫄곕━
            x1=@your_position[first_index][0]
            y1=@your_position[first_index][1]
            x2=@your_position[second_index][0]
            y2=@your_position[second_index][1]
            elsif state == 1 # �� �뚯씠�� �곷��� 嫄곕━
            x1=@my_position[first_index][0]
            y1=@my_position[first_index][1]
            x2=@your_position[second_index][0]
            y2=@your_position[second_index][1]
            else # �대룎 �먭컻 嫄곕━
            x1=@my_position[first_index][0]
            y1=@my_position[first_index][1]
            x2=@my_position[second_index][0]
            y2=@my_position[second_index][1]
        end
        
        distance1=(x2-x1).abs
        distance2=(y2-y1).abs
        
        return Math.sqrt(distance1*distance1+distance2*distance2)
    end
    #########
    def judge_state2
        n = @your_position.size
        ddd = Array.new(n)
        max_index_list = Array.new([0])
        
        
        for i in (0..n-1)
            count4you=0
            j_array = Array.new()
            for j in (0..n-1)
                if j!=i
                    if get_distance(i,j,0) < 100
                        count4you += 1
                        j_array << j
                    end
                end
            end
            ddd[i] = count4you
            if ddd[max_index_list[0]] < count4you
                max_index_list = [i]
                max_index_list.concat(j_array)
            end
        end
        if max_index_list.size > 2
            @state = 2
        end
        return max_index_list
    end
    ################
    
    def simulate(final_index_list,stone_index)
        dx = (@my_position[stone_index[0]][0]-@your_position[stone_index[1]][0]).abs
        dy = (@my_position[stone_index[0]][1]-@your_position[stone_index[1]][1]).abs
        s = Math.sqrt(dx*dx+dy*dy)
        max_phi = Math.asin(50.0/s)
        cccount = nil
        cccount = Array.new()
        count_1 = nil
        count_1 = Array.new()
        count_2 = nil
        count_2 = Array.new()
        k = 0
        space = nil
        space = CP::Space.new
        theta = nil
        theta = Array.new()
        for i in ((-1*max_phi*1000).to_i..(max_phi*1000).to_i)
            time = 0.0
            count_1[k] = 0
            count_2[k] = 0
            
            my_stones = nil
            your_stones = nil
            my_stones = Array.new
            your_stones = Array.new
            max_out = 0
            l = 0
            @my_position.each do |my|
                my_stones[l] = Stone.new(my[0],my[1])
                space.add_body(my_stones[l].body)
                space.add_shape(my_stones[l].shape)
                l += 1
            end
            
            j = 0
            final_index_list.each do |list|
                your_stones[j] = Stone.new(@your_position[list][0],@your_position[list][1])
                space.add_body(your_stones[j].body)
                space.add_shape(your_stones[j].shape)
                j+=1
            end
            theta[k] = i/1000.0
            x_speed = (your_stones[0].body.p.x-my_stones[stone_index[0]].body.p.x)*Math.cos(i/1000.0)-(your_stones[0].body.p.y-my_stones[stone_index[0]].body.p.y)*Math.sin(i/1000.0)
            y_speed = (your_stones[0].body.p.x-my_stones[stone_index[0]].body.p.x)*Math.sin(i/1000.0)+(your_stones[0].body.p.y-my_stones[stone_index[0]].body.p.y)*Math.cos(i/1000.0)
            speed = Math.sqrt(x_speed.abs*x_speed.abs+y_speed.abs*y_speed.abs)
            scaled_x_speed = MAX_POWER*(x_speed)/speed
            scaled_y_speed = MAX_POWER*(y_speed)/speed
            
            
            my_stones[stone_index[0]].body.v = CP::Vec2.new(scaled_x_speed,scaled_y_speed)
            
            while time < 3
                
                space.step(TICK)
                my_stones.each do |stone|
                    stone.update
                end
                your_stones.each do |stone|
                    stone.update
                end
                
                time += TICK
                
                
                
            end
            
            my_stones.each do |stone|
                
                if stone.body.p.x > 725 or stone.body.p.x < -25 or stone.body.p.y > 725 or stone.body.p.y < -25
                    count_1[k] -= 1
                end
                
            end
            
            your_stones.each do |stone|
                
                if stone.body.p.x > 725 or stone.body.p.x < -25 or stone.body.p.y > 725 or stone.body.p.y < -25
                    count_2[k] += 1
                end
                
            end
            cccount[k] = count_1[k] + count_2[k]
            
            k +=1
            my_stones.each do |stone|
                space.remove_body(stone.body)
                space.remove_shape(stone.shape)
            end
            your_stones.each do |stone|
                space.remove_body(stone.body)
                space.remove_shape(stone.shape)
            end
        end
        
        index = 0
        index_good = 0
        max_count = 0
        
        
        cccount.each do |count2|
            if max_count < count2
                max_count = count2
                index_good = index
            end
            index += 1
        end
        
        iindex = 1
        ccc = 0
        ddd = 0
        while ccc == 0
            
            if cccount[iindex] == max_count and cccount[iindex-1] != cccount[iindex]
                iindex11 = iindex
            end
            if cccount[iindex] == max_count and cccount[iindex+1] != cccount[iindex]
                iindex22 = iindex
                ccc = 1
                ddd = 1
                elsif iindex == cccount.size-1
                ccc = 1
            end
            
            iindex +=1
            
        end
        if ddd == 1
            index_good = (iindex11+iindex22)/2.0.to_i
        end
        
        optimal_theta=theta[index_good]
        ##############################################################################################################################################################################�섃솪
        k= 0
        ccount_1 = nil
        ccount_1 = Array.new()
        ccount_2 = nil
        ccount_2 = Array.new()
        for i in (0..26)
            
            time = 0.0
            
            ccount_1[k] = 0
            ccount_2[k] = 0
            my_stones = nil
            your_stones = nil
            my_stones = Array.new
            your_stones = Array.new
            max_out = 0
            l = 0
            @my_position.each do |my|
                my_stones[l] = Stone.new(my[0],my[1])
                space.add_body(my_stones[l].body)
                space.add_shape(my_stones[l].shape)
                l += 1
            end
            
            j = 0
            final_index_list.each do |list|
                your_stones[j] = Stone.new(@your_position[list][0],@your_position[list][1])
                space.add_body(your_stones[j].body)
                space.add_shape(your_stones[j].shape)
                j+=1
            end
            
            x_speed = (your_stones[0].body.p.x
                       my_stones[stone_index[0]].body.p.x)*Math.cos(optimal_theta)-(your_stones[0].body.p.y-my_stones[stone_index[0]].body.p.y)*Math.sin(optimal_theta)
                       y_speed = (your_stones[0].body.p.x-my_stones[stone_index[0]].body.p.x)*Math.sin(optimal_theta)+(your_stones[0].body.p.y-my_stones[stone_index[0]].body.p.y)*Math.cos(optimal_theta)
                       speed = Math.sqrt(x_speed.abs*x_speed.abs+y_speed.abs*y_speed.abs)
                       scaled_x_speed = 25*(i+1)*(x_speed)/speed
                       scaled_y_speed = 25*(i+1)*(y_speed)/speed
                       
                       
                       my_stones[stone_index[0]].body.v = CP::Vec2.new(scaled_x_speed,scaled_y_speed)
                       
                       
                       
                       
                       while time < 3
                           
                           space.step(TICK)
                           my_stones.each do |stone|
                               stone.update
                           end
                           your_stones.each do |stone|
                               stone.update
                           end
                           
                           time += TICK
                           
                           
                           
                       end
                       
                       
                       
                       
                       my_stones.each do |stone|
                           if stone.body.p.x > 725 or stone.body.p.x < -25 or stone.body.p.y > 725 or stone.body.p.y < -25
                               
                               ccount_1[k] -= 1
                           end
                       end
                       
                       your_stones.each do |stone|
                           if stone.body.p.x > 725 or stone.body.p.x < -25 or stone.body.p.y > 725 or stone.body.p.y < -25
                               ccount_2[k] += 1
                           end
                           
                       end
                       
                       k +=1
                       
                       my_stones.each do |stone|
                           space.remove_body(stone.body)
                           space.remove_shape(stone.shape)
                       end
                       
                       your_stones.each do |stone|
                           space.remove_body(stone.body)
                           space.remove_shape(stone.shape)
                       end
                       
        end
        
        
        min_ccount = -100
        index = 1
        
        max_ccount = 0
        power_good = 0
        cc = 1
        for jjjjj in (0..26)
            
            if count_2[index_good] == ccount_2[jjjjj]
                
                
                
                if min_ccount < ccount_1[jjjjj]
                    
                    min_ccount = ccount_1[jjjjj]
                    
                    power_good = 25*(jjjjj+1)
                    cc = 0
                end
            end
            
        end
        
        if cc == 1
            power_good = 700
        end
        
        
        
        
        return optimal_theta,max_count,power_good
    end
    ################################################################
    
    
    ################################################################
    def calculate(positions)
        @f = File.new("log.txt","w")
        @my_position = nil
        @your_position = nil
        @state = nil
        
        #Codes here
        @my_position = positions[0]
        @your_position = positions[1]
        @state = 0
        alpha_list = nil
        final_index_list=nil
        countK = nil
        alpha_list=Array.new()
        final_index_list=Array.new()
        countK = Array.new()
        max_power = 700.0
        
        current_stone_number = 0
        index = 0
        min_length = MAX_NUMBER
        x_length = MAX_NUMBER
        y_length = MAX_NUMBER
        
        max_index_list = Array.new
        
        
        
        max_index_list = judge_state2()
        if @state==2
            min_my_index = 0
            min_distance4us = 10000
            min_distance4you = 10000
            min_your_index = 0
            m = @my_position.size
            
            for iii in (0..m-1)
                
                if min_distance4us > get_distance(iii,max_index_list[0],1)
                    min_distance4us = get_distance(iii,max_index_list[0],1)
                    min_my_index = iii
                end
            end
            for jjj in max_index_list
                
                if min_distance4you > get_distance(min_my_index,jjj,1)
                    min_distance4you = get_distance(min_my_index,jjj,1)
                    min_your_index = jjj
                end
            end
            
            optimal_theta, count,max_power = simulate(max_index_list,[min_my_index,min_your_index])
            stone_index = [[min_my_index,min_your_index],[0,0]]
            optimal_index = 0
            
            else
            
            stone_index = no_my_stone()
            alpha_list, final_index_list,countK = find_count(stone_index)
            optimal_index = determining_route(final_index_list,countK)
            finalsize = final_index_list[optimal_index].size
            
            
            optimal_theta,count,max_power=simulate(final_index_list[optimal_index],stone_index[optimal_index])
            
        end
        
        
        # �ш린�� �곕━�뚯씠 �곷� �먮쾲吏� �뚯쓣 移� �� �덈뒗 踰붿쐞 �덉뿉 �곷� �뚯씠 �덈뒗吏 �먮떒�섍퀬, 洹� 踰좏�瑜� 諛섑솚�댁＜�� 肄붾뱶瑜� 異붽� �쒕떎
        #puts your_index,my_index
        
        current_stone_number = stone_index[optimal_index][0]
        x_speed = (@your_position[stone_index[optimal_index][1]][0]-@my_position[stone_index[optimal_index][0]][0])*Math.cos(optimal_theta)-(@your_position[stone_index[optimal_index][1]][1]-@my_position[stone_index[optimal_index][0]][1])*Math.sin(optimal_theta)
        y_speed = (@your_position[stone_index[optimal_index][1]][0]-@my_position[stone_index[optimal_index][0]][0])*Math.sin(optimal_theta)+(@your_position[stone_index[optimal_index][1]][1]-@my_position[stone_index[optimal_index][0]][1])*Math.cos(optimal_theta)
        
        
        speed = Math.sqrt(x_speed.abs*x_speed.abs+y_speed.abs*y_speed.abs)
        #scaled_x_speed = (lengthofstones/2+300+30*numberofstones)*(x_speed)/speed
        #scaled_y_speed = (lengthofstones/2+300+30*numberofstones)*(y_speed)/speed
        scaled_x_speed = max_power*(x_speed)/speed
        scaled_y_speed = max_power*(y_speed)/speed
        
        #Return values
        message = positions.size
        stone_number = current_stone_number
        return [stone_number, scaled_x_speed, scaled_y_speed, message]
        
        #Codes end
    end
    
    def get_name
        "HANGUK! AI2!!!"
    end
end

s.add_handler("alggago", MyAlggago.new)

s.serve
