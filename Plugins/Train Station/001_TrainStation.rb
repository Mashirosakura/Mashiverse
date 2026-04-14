module TrainStation
  # map_id matches the Town Map point's fly destination map.
  # destination_map_id is the actual transfer target and defaults to map_id.
  DESTINATIONS = [
    {
      map_id: 2,
      destination_map_id: 4,
      x: 6,
      y: 10,
      game_switch: 60
    }
  ].freeze
end

def pbTrainStation
  scene = PokemonRegionMap_Scene.new(-1, false)
  screen = PokemonRegionMapScreen.new(scene)
  ret = screen.pbStartTrainStationScreen
  return false if !ret
  pbEasyTransfer(ret[0], ret[1], ret[2])
  return true
end

class PokemonRegionMap_Scene
  alias train_station_pbStartScene pbStartScene
  alias train_station_pbMapScene pbMapScene
  alias train_station_refresh_fly_screen refresh_fly_screen

  def pbStartScene(as_editor = false, fly_map = false, station_map = false)
    @station_map = station_map
    ret = train_station_pbStartScene(as_editor, fly_map)
    return ret if !@station_map || !@sprites
    @mode = 1
    pbRefreshTrainStationPoints
    refresh_fly_screen
    return ret
  end

  def pbMapScene
    return train_station_pbMapScene if !@station_map
    x_offset = 0
    y_offset = 0
    new_x    = 0
    new_y    = 0
    timer_start = System.uptime
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if x_offset != 0 || y_offset != 0
        if x_offset != 0
          @sprites["cursor"].x = lerp(new_x - x_offset, new_x, 0.1, timer_start, System.uptime)
          x_offset = 0 if @sprites["cursor"].x == new_x
        end
        if y_offset != 0
          @sprites["cursor"].y = lerp(new_y - y_offset, new_y, 0.1, timer_start, System.uptime)
          y_offset = 0 if @sprites["cursor"].y == new_y
        end
        next if x_offset != 0 || y_offset != 0
      end
      ox = 0
      oy = 0
      case Input.dir8
      when 1, 2, 3
        oy = 1 if @map_y < BOTTOM
      when 7, 8, 9
        oy = -1 if @map_y > TOP
      end
      case Input.dir8
      when 1, 4, 7
        ox = -1 if @map_x > LEFT
      when 3, 6, 9
        ox = 1 if @map_x < RIGHT
      end
      if ox != 0 || oy != 0
        @map_x += ox
        @map_y += oy
        x_offset = ox * SQUARE_WIDTH
        y_offset = oy * SQUARE_HEIGHT
        new_x = @sprites["cursor"].x + x_offset
        new_y = @sprites["cursor"].y + y_offset
        timer_start = System.uptime
      end
      @sprites["mapbottom"].maplocation = pbGetMapLocation(@map_x, @map_y)
      @sprites["mapbottom"].mapdetails  = pbGetMapDetails(@map_x, @map_y)
      if Input.trigger?(Input::BACK)
        if @editor && @changed
          pbSaveMapData if pbConfirmMessage(_INTL("Save changes?")) { pbUpdate }
          break if pbConfirmMessage(_INTL("Exit from the map?")) { pbUpdate }
        else
          break
        end
      elsif Input.trigger?(Input::USE) && @mode == 1
        destination = pbGetTrainStationDestination(@map_x, @map_y)
        return destination if destination
      elsif Input.trigger?(Input::USE) && @editor
        pbChangeMapLocation(@map_x, @map_y)
      end
    end
    pbPlayCloseMenuSE
    return nil
  end

  def refresh_fly_screen
    return train_station_refresh_fly_screen if !@station_map
    @sprites["help"].bitmap.clear
    @sprites.each do |key, sprite|
      next if !key.start_with?("point")
      sprite.visible = (@mode == 1)
      sprite.frame   = 0
    end
  end

  def pbRefreshTrainStationPoints
    @sprites.keys.select { |key| key.start_with?("point") }.each do |key|
      @sprites[key].dispose
      @sprites.delete(key)
    end
    k = 0
    (LEFT..RIGHT).each do |i|
      (TOP..BOTTOM).each do |j|
        next if !pbTrainStationPointVisible?(i, j)
        @sprites["point#{k}"] = AnimatedSprite.create("Graphics/UI/Town Map/icon_fly", 2, 16)
        @sprites["point#{k}"].viewport = @viewport
        @sprites["point#{k}"].x        = point_x_to_screen_x(i)
        @sprites["point#{k}"].y        = point_y_to_screen_y(j)
        @sprites["point#{k}"].visible  = (@mode == 1)
        @sprites["point#{k}"].play
        k += 1
      end
    end
  end

  def pbTrainStationConfigForDestination(destination)
    return nil if !destination
    return TrainStation::DESTINATIONS.find do |station|
      station[:map_id] == destination[0]
    end
  end

  def pbGetTrainStationDestination(x, y)
    return nil if !@map || !@map.point
    @map.point.each do |point|
      next if point[0] != x || point[1] != y
      next if point[7] && (@wallmap || point[7] <= 0 || !$game_switches[point[7]])
      destination = (point[4] && point[5] && point[6]) ? [point[4], point[5], point[6]] : nil
      next if !destination
      station = pbTrainStationConfigForDestination(destination)
      next if !station
      switch_id = station[:game_switch].to_i
      next if switch_id <= 0 || !$game_switches[switch_id]
      destination_map_id = station[:destination_map_id] || station[:map_id]
      return [destination_map_id, station[:x], station[:y]]
    end
    return nil
  end

  def pbTrainStationPointVisible?(x, y)
    return !pbGetTrainStationDestination(x, y).nil?
  end
end

class PokemonRegionMapScreen
  def pbStartTrainStationScreen
    @scene.pbStartScene(false, false, true)
    ret = @scene.pbMapScene
    @scene.pbEndScene
    return ret
  end
end


