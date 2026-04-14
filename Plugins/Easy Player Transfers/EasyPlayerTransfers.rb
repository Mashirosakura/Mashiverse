  #-----------------------------------------------------------------------------
  # * Transfer Player using appointed variables
  #   call with pbEasyTransfer(MapID,x,y)
  #   This is ideally best for passing variables from arrays for random map teleporting, or variable-based coordinate transfers.
  #-----------------------------------------------------------------------------

  def pbEasyTransfer(mapid = 0, x = 0, y = 0)
    pbFadeOutIn { pbEasyTransferLogic(mapid, x, y) }
  end

  def pbEasyTransferLogic(mapid = 0, x = 0, y = 0)
    pbFadeOutIn do
      return true if $game_temp.in_battle
      return false if $game_temp.player_transferring ||
                      $game_temp.message_window_showing ||
                      $game_temp.transition_processing
      # Set up the transfer and the player's new coordinates
      $game_temp.player_transferring = true
      $game_temp.player_new_map_id    = mapid
      $game_temp.player_new_x         = x
      $game_temp.player_new_y         = y
      pbDismountBike
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
      yield if block_given?
      pbWait(0.25)
    end
  end
