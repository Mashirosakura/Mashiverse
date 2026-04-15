#===============================================================================
# Target's Special Defense is used instead of its Defense for this move's
# calculations. (Shocking Delivery)
#===============================================================================
class Battle::Move::UseTargetSpDefInsteadOfTargetDefense < Battle::Move
  def pbGetDefenseStats(user, target)
    return target.special_defense, target.stages[:SPECIAL_DEFENSE] + Battle::Battler::STAT_STAGE_MAXIMUM
  end
end

#===============================================================================
# Prevents the target from switching out or fleeing for 5 turns. This effect
# isn't applied if either Pokémon is already prevented from switching out or
# fleeing. (Ensnaring Clamp)
#===============================================================================
class Battle::Move::TrapTargetInBattle5Turns < Battle::Move
  def pbEffectAgainstTarget(user, target)
    return if user.fainted? || target.fainted? || target.damageState.substitute
    return if Settings::MORE_TYPE_EFFECTS && target.pbHasType?(:GHOST)
    return if user.trappedInBattle? || target.trappedInBattle?
    target.effects[PBEffects::JawLock] = 5
    @battle.pbDisplay(_INTL("{1} can't run away for 5 turns!", target.pbThis))
  end


  def pbMoveFailed?(user, targets)
    if user.pbOwnSide.effects[PBEffects::Reflect] > 0
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOwnSide.effects[PBEffects::Reflect] = 5
    user.pbOwnSide.effects[PBEffects::Reflect] = 8 if user.hasActiveItem?(:LIGHTCLAY)
    @battle.pbDisplay(_INTL("{1} raised {2}'s Defense!", @name, user.pbTeam(true)))
  end
end

#===============================================================================
# Crit chance is multiplied by the number of consecutive rounds in which this
# move was used by the user. (Rainbow Glide)
#===============================================================================
class Battle::Move::CritHigherWithConsecutiveUse < Battle::Move
  def pbChangeUsageCounters(user, specialUsage)
    oldVal = user.pbOwnSide.effects[PBEffects::EchoedVoiceCounter]
    super
    if !user.pbOwnSide.effects[PBEffects::EchoedVoiceUsed]
      user.pbOwnSide.effects[PBEffects::EchoedVoiceCounter] = (oldVal >= 5) ? 5 : oldVal + 1
    end
    user.pbOwnSide.effects[PBEffects::EchoedVoiceUsed] = true
  end

  def pbBaseDamage(baseDmg, user, target)
    return baseDmg * user.pbOwnSide.effects[PBEffects::EchoedVoiceCounter]   # 1-5
  end
end

#===============================================================================
# Target's speed is halved for 3 turns. (Slobber)
#===============================================================================


#===============================================================================
# Power is doubled if Snow is active. (Frosty Runway)
#===============================================================================
class Battle::Move::DoublePowerInSnow < Battle::Move
  def pbBaseDamage(baseDmg, user, target)
    baseDmg *= 2 if @battle.field.weatherType == :Hail
    return baseDmg
  end
end

#===============================================================================
# Charges up user's next attack if it is Electric-type. (Ion Wave)
#===============================================================================
class Battle::Move::PowerUpElectricMove < Battle::Move
  def pbEffectGeneral(user)
    user.effects[PBEffects::Charge] = 2
    @battle.pbDisplay(_INTL("{1} began charging power!", user.pbThis))
    super
  end
end

#===============================================================================
# Power is mutliplied by 1.3 if Gravity is in effect. (Meteor Drop)
#===============================================================================
class Battle::Move::PowersUpInGravity < Battle::Move
  def pbBaseDamage(baseDmg, user, target)
    baseDmg = baseDmg * 1.3 if @battle.field.effects[PBEffects::Gravity] > 0
    return baseDmg
  end
end

#===============================================================================
# Seeds the target for 3 turns. Seeded Pokémon lose 1/8 of max HP at the end of 
# each round, and the Pokémon in the user's position gains the same amount.
# (Sappy Seed)
#===============================================================================
class Battle::Move::ThreeTurnLeechSeedTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.effects[PBEffects::LeechSeed] >= 0
      @battle.pbDisplay(_INTL("{1} is already seeded!", target.pbThis)) if show_message
      return true
    end
    if target.pbHasType?(:GRASS)
      @battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true))) if show_message
      return true
    end
    return false
  end

  def pbMissMessage(user, target)
    @battle.pbDisplay(_INTL("{1} evaded the attack!", target.pbThis))
    return true
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::LeechSeed] = 5
    @battle.pbDisplay(_INTL("{1} was seeded!", target.pbThis))
  end
end

#===============================================================================
# User takes recoil damage equal to 1/3 of the damage this move dealt.
# May flinch the target. (Dragon Rush[New])
#===============================================================================
class Battle::Move::RecoilThirdOfDamageDealtFlinchTarget < Battle::Move::RecoilMove
  def flinchingMove?; return true; end
  
  def pbRecoilDamage(user, target)
    return (target.damageState.totalHPLost / 3.0).round
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    chance = pbAdditionalEffectChance(user, target, 20)
    return if chance == 0
    target.pbFlinch(user) if @battle.pbRandom(100) < chance
  end
end