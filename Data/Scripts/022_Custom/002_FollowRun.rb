class Game_Follower
  alias _runfollowers_initialize initialize
  def initialize(event_data)
    _runfollowers_initialize(event_data)
    @default_character_name = event_data.character_name
  end
  
  def update_move
    was_jumping = jumping?
    if !@moved_last_frame || @stopped_last_frame
    faster = $game_player.can_run?
      if faster && pbResolveBitmap("Graphics/Characters/" + @default_character_name + "_run" )
        self.character_name = sprintf("%s_run",@default_character_name)
      else
        self.character_name = @default_character_name
      end
    end
    super
    if was_jumping && !jumping?
      spriteset = $scene.spriteset(map_id)
      spriteset&.addUserAnimation(Settings::DUST_ANIMATION_ID, self.x, self.y, true, 1)
    end
  end
  
  def update_stop
    if @stopped_last_frame
      self.character_name = @default_character_name
    end
    super
  end
end