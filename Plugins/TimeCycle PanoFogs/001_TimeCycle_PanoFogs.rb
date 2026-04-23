module TimeCyclePanoFogs
  module_function

  def current_suffix
    return nil if !Settings::TIME_SHADING
    time_now = pbGetTimeNow
    return "night" if PBDayNight.isNight?(time_now)
    return "eve" if PBDayNight.isEvening?(time_now)
    return nil
  end

  def variant_filename(folder, filename)
    return filename if !filename.is_a?(String) || filename.empty?
    suffix = current_suffix
    return filename if !suffix
    variant = sprintf("%s_%s", filename, suffix)
    return variant if pbResolveBitmap(sprintf("Graphics/%s/%s", folder, variant))
    return filename
  end
end

class AnimatedPlane
  alias timecycle_pano_fogs_set_panorama set_panorama
  alias timecycle_pano_fogs_set_fog set_fog

  def set_panorama(file, hue = 0)
    file = TimeCyclePanoFogs.variant_filename("Panoramas", file)
    timecycle_pano_fogs_set_panorama(file, hue)
  end

  def set_fog(file, hue = 0)
    file = TimeCyclePanoFogs.variant_filename("Fogs", file)
    timecycle_pano_fogs_set_fog(file, hue)
  end
end

class Spriteset_Map
  alias timecycle_pano_fogs_update update

  def update
    timecycle_suffix = TimeCyclePanoFogs.current_suffix
    if @timecycle_pano_fogs_suffix != timecycle_suffix
      @timecycle_pano_fogs_suffix = timecycle_suffix
      @panorama_name = nil
      @fog_name = nil
    end
    timecycle_pano_fogs_update
  end
end
