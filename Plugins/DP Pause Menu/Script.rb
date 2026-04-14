#==============================================================================#
#                         Diamond/Pearl Pause Menu                             #
#                                  by Marin                                    #
#==============================================================================#
#                                Instructions                                  #
#                                                                              #
#  To call the Pause menu individually (not by pressing B), use `pbPauseMenu`  #
#                                                                              #
# To make/add your own options, find `@options = []`. Underneath, all options  #
#        are initialized and added. They follow a very simple format:          #
#           [displayname, unselected, selected, code, (condition)]             #
# `displayname` : This is what's actually displayed on screen.                 #
# `unselected` : This is the icon that will be displayed when the option is    #
#                NOT selected. For it to be gender dependent, make it an array #
# `selected` : This is the icon that will be displayed when the option IS      #
#              selected. For it to be gender dependent, make it an array.      #
# `code` : This is what's executed when you click the button.                  #
# `condition` : If you only want the option to be visible at certain times,    #
#               this is where you can add a condition (e.g. $player.pokedex). #
#==============================================================================#
#                    Please give credit when using this.                       #
#==============================================================================#

# Calls the Pause menu
def pbPauseMenu
  DP_PauseMenu.new
end

# This overwrites the old pause menu. Take/comment out these 10 lines to keep
# the old Pause menu.
class Scene_Map
  def call_menu
    $game_temp.menu_calling = false
    $game_temp.in_menu = true
    $game_player.straighten
    $game_map.update
    pbPauseMenu # Calls the DP Pause Menu
    $game_temp.in_menu = false
  end
end

# Variables used to store last selected index.
class PokemonGlobalMetadata
  attr_accessor :last_menu_index
end

class DP_PauseMenu
  # Base color of the displayed text
  BaseColor = Color.new(82,82,90)
  # Shadow color of the displayed text
  ShadowColor = Color.new(165,165,173)
  
  def initialize
    @options = []
	
	# Retire: Safari
	@options << ["RETIRE", "retireA", "retireB", proc {
		@sprites.visible = false
		if pbConfirmMessage(_INTL("Would you like to leave the Safari Game right now?"))
		  @done = true
		  pbSafariState.decision = 1
		  pbSafariState.pbGoToStart
		end
		@sprites.visible = true
    }] if pbInSafari?
	
	# Retire: Bug-Catching Contest
	@options << ["RETIRE", "retireA", "retireB", proc {
		@sprites.visible = false
		if pbConfirmMessage(_INTL("Would you like to end the Contest now?"))
		  @done = true
		  pbBugContestState.pbStartJudging
		  next true
		end
		@sprites.visible = true
    }] if pbInBugContest?
	
	
	# Pokedex
    @options << ["POKéDEX", "pokedexA", "pokedexB", proc {
      if Settings::USE_CURRENT_REGION_DEX
        pbFadeOutIn do
          scene = PokemonPokedex_Scene.new
          screen = PokemonPokedexScreen.new(scene)
          screen.pbStartScreen
        end
      elsif $player.pokedex.accessible_dexes.length == 1
        $PokemonGlobal.pokedexDex = $player.pokedex.accessible_dexes[0]
        pbFadeOutIn do
          scene = PokemonPokedex_Scene.new
          screen = PokemonPokedexScreen.new(scene)
          screen.pbStartScreen
        end
      else
        pbFadeOutIn do
          scene = PokemonPokedexMenu_Scene.new
          screen = PokemonPokedexMenuScreen.new(scene)
          screen.pbStartScreen
        end
      end 
    }] if $player.has_pokedex
	
	# Party Menu
    @options << ["POKéMON", "pokemonA", "pokemonB", proc {
      hiddenmove = nil
      pbFadeOutIn do
        sscene = PokemonParty_Scene.new
        sscreen = PokemonPartyScreen.new(sscene, $player.party)
        hiddenmove = sscreen.pbPokemonScreen
        if hiddenmove
          @sprites.visible = false
          @done = true
        end
      end
      if hiddenmove
        $game_temp.in_menu = false
        Kernel.pbUseHiddenMove(hiddenmove[0],hiddenmove[1])
      end
    }] if $player.party.size > 0
	
	# Bag
    @options << ["BAG", "bagA", ["bagBm", "bagBf"], proc {
      item = 0
      pbFadeOutIn do
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene, $bag)
        item = screen.pbStartScreen
      end
      next false if !item
      $game_temp.in_menu = false
      pbUseKeyItemInField(item)
      next true
    }] if !pbInBugContest?
	
	# Add Pokegear
	@options << ["POKéGEAR", "pokegearA", ["pokegearBm", "pokegearBf"], proc {
		pbFadeOutIn do
			scene = PokemonPokegear_Scene.new
			screen = PokemonPokegearScreen.new(scene)
			screen.pbStartScreen
			($game_temp.fly_destination) ? @done = true : @sprites.visible = true
		end
		next pbFlyToNewLocation
    }] if $player.has_pokegear
	
	# Town Map
	@options << ["TOWN MAP", "townMapA", "townMapB", proc {
		pbFadeOutIn do
			scene = PokemonRegionMap_Scene.new(-1, false)
			screen = PokemonRegionMapScreen.new(scene)
			ret = screen.pbStartScreen
			($game_temp.fly_destination) ? @done = true : @sprites.visible = true
		end
		next pbFlyToNewLocation
    }] if !$player.has_pokegear & $bag.has?(:TOWNMAP)
	
	# Trainer Card
    @options << [$player.name, "PlayercardA", "PlayercardB", proc {
		pbFadeOutIn do
			scene = PokemonTrainerCard_Scene.new
			screen = PokemonTrainerCardScreen.new(scene)
			screen.pbStartScreen
		end
    }]
	
	# Save Game
    @options << ["SAVE", "saveA", ["saveBm","saveBf"], proc {
		@sprites.visible = false
		pbFadeOutIn do
		  if PluginManager.installed?("HGSS Multi-Save")
			(UI::Save.new.main) ? @done = true : @sprites.visible = true
		  else
			scene = PokemonSave_Scene.new
			screen = PokemonSaveScreen.new(scene)
			(screen.pbSaveScreen) ? @done = true : @sprites.visible = true
		  end
		end
    }] if $game_system && !$game_system.save_disabled && !pbInSafari? && !pbInBugContest?
	
	# Options
    @options << ["OPTIONS", "optionsA", "optionsB", proc {
		pbFadeOutIn do
			scene = PokemonOption_Scene.new
			screen = PokemonOptionScreen.new(scene)
			screen.pbStartScreen
			pbUpdateSceneMap
		end
    }]
	
	# Uncomment the Exit/Quit option below if desired :)
	# But you will likely want to edit the UI to properly display 8+ options, tho :/
	# Or you could make this mutually exclusive with the Pokegear & Town Map via changing line 208 to:
	# }] if !pbInSafari? && !pbInBugContest? && !$player.has_pokegear & !$bag.has?(:TOWNMAP)
	
	# # Exit / Quit
    # @options << ["QUIT GAME", "exitA", "exitB", proc {
		# @sprites.visible = false
		# if pbConfirmMessage(_INTL("Are you sure you want to quit the game?"))
		  # # Suggested by http404error: https://eeveeexpo.com/resources/1059/
		  # SaveData.mark_values_as_unloaded
		  # pbBGMFade(1.0)
		  # pbBGSFade(1.0)
		  # @done = true
		  # $scene = pbCallTitle
		# end
		# @sprites.visible = true
    # }] if !pbInSafari? && !pbInBugContest?
	
	
	# End @options
	
    @count = @options.size
    return if @count == 0
    $PokemonGlobal.last_menu_index ||= 0
    @option = $PokemonGlobal.last_menu_index
    @option = 0 if @option >= @options.size
    @done = false
    @i = 0
    @scaling = 0
	
	# # Location Window: Un-comment below if v22 / dev branch location signposts has been :)
	# # ^ Also un-comment line 351 ("@sprites2.dispose")
	# map_name = $game_map.name
	# location_sign_graphic = $game_map.metadata&.location_sign || Settings::DEFAULT_LOCATION_SIGN_GRAPHIC
	# @sprites2 = SpriteHash.new
	# @sprites2["Location"] = LocationWindow.new(map_name, location_sign_graphic, false, @viewport)
	# # Delete any location window currently being displayed
	# $scene.spriteset.usersprites.each { |sprite| sprite.dispose if sprite.is_a?(LocationWindow) }
	
    @viewport = Viewport.new(Graphics.width - 204, 4, 200, 24 + 48 * @count)
    @viewport.z = 99999
    @sprites = SpriteHash.new
    @sprites["bgTop"] = Sprite.new(@viewport)
    @sprites["bgTop"].bmp("Graphics/UI/DP Pause Menu/bgTop")
    @sprites["bgMid"] = Sprite.new(@viewport)
    @sprites["bgMid"].bmp("Graphics/UI/DP Pause Menu/bgMid")
    @sprites["bgMid"].y = 12
    @sprites["bgMid"].zoom_y = 48 * @count
    @sprites["bgBtm"] = Sprite.new(@viewport)
    @sprites["bgBtm"].bmp("Graphics/UI/DP Pause Menu/bgBtm")
    @sprites["bgBtm"].y = 12 + @sprites["bgMid"].zoom_y
    @sprites["sel"] = Sprite.new(@viewport)
    @sprites["sel"].bmp("Graphics/UI/DP Pause Menu/selector")
    @sprites["sel"].xyz = 8, 10 + 48 * @option, 1
    @sprites["txt"] = TextSprite.new(@viewport)
    for i in 0...@options.size
      @sprites["txt"].draw([
          @options[i][0],72,26 + 48 * i,0,BaseColor,ShadowColor
      ])
      @sprites[@options[i][0]] = Sprite.new(@viewport)
      idx = (i == @option ? 2 : 1)
      path = @options[i][idx]
      path = path[$player.gender] if path.is_a?(Array)
      @sprites[@options[i][0]].bmp("Graphics/UI/DP Pause Menu/#{path}")
      @sprites[@options[i][0]].center_origins
      @sprites[@options[i][0]].xyz = 39, 36 + 48 * i
    end
    pbSEPlay("GUI menu open")
    main
  end
  
  def main
    loop do
      update
      old = @option
      if Input.repeat?(Input::DOWN)
        @option += 1
        @option = 0 if @option == @count
        changed = true
      end
      if Input.repeat?(Input::UP)
        @option -= 1
        @option = @count - 1 if @option == -1
        changed = true
      end
      if $mouse
        for i in 0...@count
          if i != @option && $mouse.inArea?(316,14 + 48 * i,184,52)
            @option = i
            changed = true
          end
        end
      end
      confirmed = ($mouse && $mouse.x >= 316 && $mouse.x <= 500 && $mouse.y >= 14 &&
         $mouse.y <= 14 + 48 * @count && $mouse.click?)
      confirmed = true if Input.trigger?(Input::C)
      if changed
        pbPlayCursorSE
        $PokemonGlobal.last_menu_index = @option
        path = @options[old][1]
        path = path[$player.gender] if path.is_a?(Array)
        @sprites[@options[old][0]].bmp("Graphics/UI/DP Pause Menu/#{path}")
        @sprites[@options[old][0]].angle = 0
        @sprites[@options[old][0]].zoom_x = 1
        @sprites[@options[old][0]].zoom_y = 1
        @sprites["sel"].y = 10 + 48 * @option
        path = @options[@option][2]
        path = path[$player.gender] if path.is_a?(Array)
        @sprites[@options[@option][0]].bmp("Graphics/UI/DP Pause Menu/#{path}")
        changed = false
        @scaling = 0
      end
      if confirmed
        pbPlayDecisionSE
        @options[@option][3].call
        Input.update
      end
      confirmed = false
      if @done
        break
      elsif Input.trigger?(Input::B)
        pbPlayCancelSE
        break
      end
    end
    dispose
  end
  
  def update
    Graphics.update
    Input.update
    pbUpdateSceneMap
    if @scaling
      @scaling += 1
      case @scaling
      when 1..4
        @sprites[@options[@option][0]].zoom_x += 0.05
        @sprites[@options[@option][0]].zoom_y += 0.05
      when 8..12
        @sprites[@options[@option][0]].zoom_x -= 0.05
        @sprites[@options[@option][0]].zoom_y -= 0.05
      end
      @scaling = nil if @scaling == 12
    else
      @i += 1
      case @i
      when 1..6
        @sprites[@options[@option][0]].angle -= 2
      when 7..18
        @sprites[@options[@option][0]].angle += 2
      when 19..24
        @sprites[@options[@option][0]].angle -= 2
      end
      @i = 0 if @i == 24
    end
  end
  
  def dispose
    @sprites.dispose
	#@sprites2.dispose # Used for Location Signpost
    @viewport.dispose
    Input.update
  end
end