require './ros_tcp.rb'

robot1 = Robot.new('192.168.1.42', 9090)
robot1.connect

# メッセージを準備
# グループ名と各関節の名前はロボットによって適宜変更してください
request_message = {
  goal: {
    request: {
      group_name: 'motomini',  # ロボットアームのグループ名
      goal_constraints: [{
        joint_constraints: [
          { joint_name: 'joint_1_s', position: 1.0 },
          { joint_name: 'joint_2_l', position: 0.0 },  # joint_2_lの目標位置
          { joint_name: 'joint_3_u', position: 0.0 },  # joint_3_uの目標位置
          { joint_name: 'joint_4_r', position: 0.0 },  # joint_4_rの目標位置
          { joint_name: 'joint_5_b', position: 0.0 },  # joint_5_bの目標位置
          { joint_name: 'joint_6_t', position: 0.0 }   # joint_6_tの目標位置
        ]
      }]
    }
  }
}

robot1.send_msg('/move_group/goal', request_message, 1)
robot1.disconnect
