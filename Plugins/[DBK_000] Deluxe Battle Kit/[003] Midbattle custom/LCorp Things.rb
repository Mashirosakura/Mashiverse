################################################################################
# Plays low HP ME when the player's Pokemon reach critical health.
################################################################################

MidbattleHandlers.add(:midbattle_global, :low_hp_me,
  proc { |battle, idxBattler, idxTarget, trigger|
    battler = battle.battlers[idxBattler]
    next if !battler || !battler.pbOwnedByPlayer?
    playedME = false unless defined?(@played_me_battlers) && @played_me_battlers.is_a?(Hash)
    @played_me_battlers ||= {}

    case trigger
    #---------------------------------------------------------------------------
    # Restores original state when HP is restored to healthy.
    when "BattlerHPRecovered_player"
      next unless @played_me_battlers[battler]
      next unless battler.hp > battler.totalhp / 2
      @played_me_battlers[battler] = false
    #---------------------------------------------------------------------------
    # Plays low HP ME when HP is critical.
    when "BattlerHPCritical_player"
      next if @played_me_battlers[battler]
      pbMEPlay("lowHP")
      @played_me_battlers[battler] = true
    #---------------------------------------------------------------------------
    # Restores original state when sending out a healthy Pokemon.
    # Plays low HP ME when sending out a Pokemon with critical HP.
    when "AfterSendOut_player"
      @played_me_battlers[battler] = false
      next unless battler.hasLowHP?
      pbMEPlay("lowHP")
      @played_me_battlers[battler] = true
    end
  }
)

class Battle::Scene
  def pbDisplayMessage(msg, brief = false)
    pbWaitMessage
    pbShowWindow(MESSAGE_BOX)
    cw = @sprites["messageWindow"]
    cw.setText(msg)
    PBDebug.log_message(msg)
    yielded = false
    timer_start = nil
    loop do
      pbUpdate(cw)
      if !cw.busy?
        if !yielded
          yield if block_given?   # For playing SE as soon as the message is all shown
          yielded = true
        end
        if brief
          # NOTE: A brief message lingers on-screen while other things happen. A
          #       regular message has to end before the game can continue.
          @briefMessage = true
          break
        end
      end

      waiting_for_advance = !brief && (cw.pausing? || !cw.busy?)
      timer_start = System.uptime if waiting_for_advance && !timer_start
      timer_start = nil if !waiting_for_advance
      if timer_start && System.uptime - timer_start >= MESSAGE_PAUSE_TIME
        if cw.pausing?
          cw.skipAhead
          timer_start = nil
        elsif !cw.busy?
          cw.text = ""
          cw.visible = false
          break
        end
      end

      if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE) || @abortable
        if cw.busy?
          pbPlayDecisionSE if cw.pausing? && !@abortable
          cw.skipAhead
          timer_start = nil
        elsif !@abortable
          cw.text = ""
          cw.visible = false
          break
        end
      end
    end
  end
  alias pbDisplay pbDisplayMessage
end