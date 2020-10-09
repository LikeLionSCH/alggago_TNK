require "xmlrpc/server"
require "socket"
require 'chipmunk'

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

# Physical information
WIDTH, HEIGHT = 1000, 700
STONE_DIAMETER = 50.0
RESTITUTION = 0.9

def sgn(x)
  x <=> 0
end

# Debugging information
FILENAME = "log_simple03.txt"
def logging text
  begin
    puts "beginning logging"
    file = File.open(FILENAME,'a')
    file.write(text+"\n")
  rescue IOError => e
  ensure
    file.close unless file.nil?
  end
end

logging "\nbeginning------------------------"
class MyAlggago
  def calculate(positions)
    logging "at the head of calculating"
    message = Array.new

    v_to_center = CP::Vec2.new(STONE_DIAMETER/2.0, STONE_DIAMETER/2.0)

    my_position = positions[0]
    your_position = positions[1]

    vec_position_my = my_position.map { |e| vec2(e[0],e[1]) + v_to_center }
    vec_position_your = your_position.map { |e| vec2(e[0],e[1]) + v_to_center }

    num_my_closest, num_your_closest = closest_stones(vec_position_my, vec_position_your)

    v_my_closest = vec_position_my[num_my_closest]
    v_your_closest = vec_position_your[num_your_closest]
    
    #max_indices = -1
    #idx_many_my, idx_many_your = -1
    #vec_position_my.each_with_index do |v_my, idx_my|
    #  vec_position_your.each_with_index do |v_your, idx_your|
    #    in_range_indices = indice_in_range(v_my, v_your, vec_position_my, vec_position_your)
        #alpha_max = get_alpha_max(v_my, v_your)
        #alpha_min = -alpha_max
        #alpha = Anlge.new(v_your - v_my, v_my, alpha_max, alpha_min)
        #in_range_indices = in_the_range(v_my, v_your, alpha_min, alpha_max, vec_position_my, vec_position_your)
    #    num_indices = in_range_indices.length
        #logging "#num_indices: #{num_indices}, max_indices: #{max_indices}"
    #    if (num_indices > max_indices) && is_free_path?(v_my, v_your, vec_position_my, vec_position_your)
    #      idx_many_my, idx_many_your = idx_my, idx_your
    #      max_indices = num_indices
    #      logging "#num_indices: #{num_indices}, max_indices: #{max_indices}"
    #      logging "idices: #{idx_many_my}, #{idx_many_your}"
    #    end
    #  end
    #end
    #logging "flag11"
    idx_many_my, idx_many_your = get_indices_many(vec_position_my, vec_position_your)
    results = get_indices_exist(vec_position_my, vec_position_your, 0.4)
    #logging "flag33: #{results[0]}"
    if results[0]
      #logging "flag44: #{results}"
      idx_min_angle_my, idx_min_angle_your, min_alpha = results[1], results[2], results[3]
      v_min_angle_my = vec_position_my[idx_min_angle_my]
      v_min_angle_your = vec_position_your[idx_min_angle_your]
      if alpha_sign(v_min_angle_my, v_min_angle_your) > 0
        min_alpha = min_alpha.abs
      else
        min_alpha = min_alpha.abs * (-1)
      end
      velocity = get_velocity_alpha(v_min_angle_my, v_min_angle_your,min_alpha)
      num_my_selected = idx_min_angle_my
    else
      velocity = get_velocity_theta_attenu(v_my_closest, v_your_closest, 700.0, 0.1)
      num_my_selected = num_my_closest
    end
    #logging "flgg55"
    #message << "possible_indices: #{angles}"
    #logging "flag22, idx_many_my: #{idx_many_my}"
    v_my_many = vec_position_my[idx_many_my]
    v_your_many = vec_position_your[idx_many_your]

    alpha_max = get_alpha_max(v_my_many, v_your_many)
    alpha_min = -alpha_max

    in_range_indices = in_the_range(v_my_many, v_your_many, alpha_min, alpha_max, vec_position_my, vec_position_your)
    message << "indices in the range: #{in_range_indices}"
    logging "in_range_indices: #{in_range_indices}"

    unless in_range_indices.length == 0
      idx_OB1 = in_range_indices[rand(in_range_indices.length)] 
      logging "idx_OB1: #{idx_OB1}"

      v_OB1 = vec_position_your[idx_OB1]
      logging "v_OB1: #{v_OB1}"
      #velocity = v_two_shot(v_my_many, v_your_many, v_OB1, alpha_max*(0.5))
      #num_my_selected = idx_many_my
    else
      #velocity = get_velocity_theta_attenu(v_my_closest, v_your_closest, 700.0, 0.2)
      #num_my_selected = num_my_closest
    end
    

    #Return values
    message = message.to_s
    stone_number = num_my_selected
    stone_x_strength = velocity.x * 700.0
    stone_y_strength = velocity.y * 700.0
    return [stone_number, stone_x_strength, stone_y_strength, message]
  end

  def get_name; "TEAM_AhnJeon"; end

  private
  def get_velocity_theta_max(v_OA, v_OB, speed)
    v_AB = v_OB - v_OA
    v_AB_norm = v_AB.normalize
    mag_AB = v_AB.length.to_f
    theta_max = Math::asin(STONE_DIAMETER/mag_AB)

    theta = theta_max
    vec_rot_theta = lambda {|theta| vec2(Math::cos(theta), Math::sin(theta))}
    return v_AB_norm.rotate(vec_rot_theta[theta]) * speed
  end

  def get_velocity_theta_attenu(v_OA, v_OB, speed, attenu)
    # attenu ranges from -1 to 1
    v_AB = v_OB - v_OA
    v_AB_norm = v_AB.normalize
    mag_AB = v_AB.length.to_f
    theta_max = Math::asin(STONE_DIAMETER/mag_AB)

    theta = theta_max * attenu
    vec_rot_theta = lambda {|theta| vec2(Math::cos(theta), Math::sin(theta))}
    return v_AB_norm.rotate(vec_rot_theta[theta]) * speed
  end

  def get_velocity_alpha(v_OA, v_OB, alpha)
    vec_rot_theta = lambda {|theta| vec2(Math::cos(theta), Math::sin(theta))}
    v_BA = v_OA - v_OB
    v_BAp = v_BA.normalize.rotate(vec_rot_theta[alpha]) * (STONE_DIAMETER)
    v_AAp = v_BAp - v_BA
  end

  def closest_stones(vec_position_my, vec_position_your)
    dist_min = HEIGHT*Math::sqrt(2).to_f
    index_my_current = -1
    index_your_current = -1
    vec_position_my.each_with_index do |my, index_my|
      vec_position_your.each_with_index do |your, index_your|
        distance = my.dist(your)
        if distance <= dist_min
          dist_min = distance
          index_my_current = index_my
          index_your_current = index_your
        end
      end
    end
    return index_my_current, index_your_current
  end

  def get_indices_exist(v_mines, v_yours, alpha_B1_ratio)
    idx_my_slected, idx_your_selected = nil

    possible_indices = Array.new
    angles = Array.new
    min_alpha = Math::PI
    max_indices = -1
    idx_many_my, idx_many_your = -1
    v_mines.each_with_index do |v_my, idx_my|
      v_yours.each_with_index do |v_your, idx_your|
        in_range_indices = indice_in_range(v_my, v_your, v_mines, v_yours)
        num_indices = in_range_indices.length
        if (num_indices >= 1) && is_free_path?(v_my, v_your, v_mines, v_yours)
          alpha0 = Angle.new(v_my-v_your,v_your,nil)
          in_range_indices.each do |in_range_idx|
            v_OB1 = v_yours[in_range_idx]
            v_ref = v_your - v_OB1
            logging "v_ref: #{v_ref.length}"
            alpha1_max = get_alpha_max(v_your, v_OB1)
            alpha1_1 = Angle.new(v_ref, v_OB1, alpha1_max * alpha_B1_ratio)
            alpha1_2 = Angle.new(v_ref, v_OB1, -alpha1_max * alpha_B1_ratio)
            alpha0_1 = alpha1_1.transform_stone(alpha0)
            alpha0_2 = alpha1_2.transform_stone(alpha0)
            #angles << alpha
            if (alpha0_1.specific_angle.abs < min_alpha.abs)
              min_alpha = alpha0_1.specific_angle
              idx_my_slected, idx_your_selected = idx_my, idx_your
            end
            if (alpha0_2.specific_angle.abs < min_alpha.abs)
              min_alpha = alpha0_2.specific_angle
              idx_my_slected, idx_your_selected = idx_my, idx_your
            end            
          end
          #possible_indices << [idx_my, idx_your]
        end
      end
    end
    unless min_alpha == Math::PI
      return [true, idx_my_slected, idx_your_selected, min_alpha] #angles #possible_indices
    else
      return [false]
    end
  end

  def get_indices_many(v_mines, v_yours)
    max_indices = -1
    idx_many_my, idx_many_your = -1
    v_mines.each_with_index do |v_my, idx_my|
      v_yours.each_with_index do |v_your, idx_your|
        in_range_indices = indice_in_range(v_my, v_your, v_mines, v_yours)
        num_indices = in_range_indices.length
        #logging "#num_indices: #{num_indices}, max_indices: #{max_indices}"
        if (num_indices > max_indices) && is_free_path?(v_my, v_your, v_mines, v_yours)
          idx_many_my, idx_many_your = idx_my, idx_your
          max_indices = num_indices
          logging "#num_indices: #{num_indices}, max_indices: #{max_indices}"
          logging "idices: #{idx_many_my}, #{idx_many_your}"
        end
      end
    end
    return idx_many_my, idx_many_your
  end

  def reduce_edge
    return 0.5
  end

  def alpha_sign(v_OA,v_OB)
    v_AB = v_OB - v_OA
    crosses = v_AB.cross(closer(v_OB))
    return sgn(crosses)*(-1)
  end

  def closer(v)
    v_center = vec2(HEIGHT/2.0, HEIGHT/2.0)
    #angle = v_center.dot(v).to_angle
    angle = (v - v_center).to_angle
    one = Math::PI/4.0
    two = one*2
    three = one*3
    if (angle<one)&&(angle>-one)
      return vec2(1,0)
    elsif (angle>one)&&(angle<one*3)
      return vec2(0,1)
    elsif (angle<-one)&&(angle>-three)
      return vec2(0,-1)
    else
      return vec2(-1,0)
    end
  end

  def get_alpha_max(v_OA, v_OB)
    v_AB = v_OB - v_OA
    m_AB = v_AB.length
    if m_AB < STONE_DIAMETER
      m_AB = STONE_DIAMETER
    end
    alpha_max = Math.acos(STONE_DIAMETER/m_AB)
    return alpha_max * reduce_edge
  end

  def indice_in_range(v_OA, v_OB, v_mines, v_yours)
    alpha_max = get_alpha_max(v_OA, v_OB)
    alpha_min = -alpha_max
    return in_the_range(v_OA, v_OB, alpha_min, alpha_max, v_mines, v_yours)
  end

  def in_the_range(v_OA, v_OB, alpha_min, alpha_max, v_mines, v_yours)
    in_range_indices = Array.new
    #logging "in the range"
    v_AB = v_OB - v_OA
    vec_rot_theta = lambda {|theta| vec2(Math::cos(theta), Math::sin(theta))}
    v_yours.each_with_index do |v_your, idx|
      #logging "in the loop: v_your, idx = #{v_your}, #{idx}"
      next if v_OB == v_your
      v_test = v_your - v_OB
      v_BPmax = v_AB.rotate(vec_rot_theta[alpha_max])
      v_BPmin = v_AB.rotate(vec_rot_theta[alpha_min])
      #logging "flag1: v_BPmin: #{v_BPmin}"
      #logging "in the if: v_BPmin.cross(v_test): #{v_BPmin.cross(v_test)}"
      #logging "in the if: v_BPmax.cross(v_test: #{v_BPmax.cross(v_test)}"
      if (v_BPmin.cross(v_test)>0) && (v_BPmax.cross(v_test)<0)
        in_range_indices << idx
      end
    end
    return in_range_indices
  end

  def v_two_shot(v_OA, v_OB, v_OC, alpha_C)
    logging "in v_two_shot"
    vec_rot_theta = lambda {|theta| vec2(Math::cos(theta), Math::sin(theta))}
    v_BC = v_OC - v_OB
    v_CB = -v_BC
    v_CBp = v_CB.rotate(vec_rot_theta[alpha_C]).normalize * STONE_DIAMETER
    v_BBp = v_CBp + v_BC
    v_BAp = v_BBp.normalize * (-STONE_DIAMETER)
    v_BA = v_OA - v_OB
    v_AAp = v_BAp - v_BA
    return v_AAp
  end

  def in_the_path?(v_OA, v_OB, v_OC)
    ## Description
    # v_OC is a position for the stone being tested 
    # whether it is along the path from v_OA to v_OB

    ## Defining some vectors
    v_AB = v_OB - v_OA
    v_AC = v_OC - v_OA
    m_AB = v_AB.length
    v_OAp = v_OA * (STONE_DIAMETER/m_AB) + v_OB * (1-STONE_DIAMETER/m_AB)
    v_ApC = v_OC - v_OAp

    ## Testing areas
    around_v_OAp = v_OAp.dist(v_OC) <= STONE_DIAMETER
    between_A_B = (v_AB.dot(v_AC) >= 0) && (v_AB.dot(v_ApC) <= 0)
    near_path = ( v_AC - v_AC.project(v_AB) ).length <= STONE_DIAMETER
    in_rectangle = near_path && between_A_B
    return around_v_OAp || in_rectangle
  end

  def is_free_path?(v_OA, v_OB, v_position_my, v_position_your)
    [v_position_my, v_position_your].each do |v_set|
      v_set.each do |v|
        is_itself = (v == v_OA) || (v == v_OB)
        unless is_itself
          return false if in_the_path?(v_OA, v_OB, v)
        end
      end
    end 
    return true
  end

end

class Angle
  attr_accessor :max_angle, :min_angle, :v_ref, :angle_ref, :v_stone, :specific_angle
  def initialize(v_referecnce, v_stone, specific_angle)
    @v_ref = v_referecnce
    @angle_ref = v_referecnce.to_angle
    @v_stone = v_stone
    @min_angle = nil
    @max_angle = nil
    @specific_angle = specific_angle
  end

  def transform_stone(new_stone_Angle)
    v_stone_new = new_stone_Angle.v_stone
    v_old_to_new = v_stone_new - @v_stone
    puts "v_old_to_new: #{v_old_to_new}"
    r = v_old_to_new.length
    alpha_in_old = alpha(@specific_angle, r)
    puts "alpha_in_old: #{alpha_in_old}"
    alpha_in_new = transform_angle_ref(alpha_in_old, new_stone_Angle.angle_ref)
    puts "alpha_in_new: #{alpha_in_new}"
    return Angle.new(new_stone_Angle.v_ref, new_stone_Angle.v_stone, alpha_in_new)
  end

  def transform_angle_ref(angle, angle_ref_new)
    return @angle_ref - angle_ref_new + angle
  end

  def alpha(alpha1, r)
    tan_alpha = (-STONE_DIAMETER*Math::sin(alpha1))/(r- STONE_DIAMETER*Math::cos(alpha1))
    return Math::atan(tan_alpha)
  end
end

s.add_handler("alggago", MyAlggago.new)
s.serve
