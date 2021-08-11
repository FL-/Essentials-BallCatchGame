#===============================================================================
# * Ball Catch Game - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It's a simple minigame where the player
# must pick the balls that are falling at screen.
#
#===============================================================================
#
# To this script works, put it above main, put a 512x384 background for this
# screen in "Graphics/Pictures/backgroundcatch" location, a 80x44 
# catcher/basket at "Graphics/Pictures/catcher" and a 20x20 ball at 
# "Graphics/Pictures/ballcatch". May works with other image sizes.
#  
# To call this script, use the script command 'pbCatchGame(X)' where X is the
# number of total balls. This method will return the number of picked balls.
#
#===============================================================================

if defined?(PluginManager)
  PluginManager.register({                                                 
    :name    => "Ball Catch Game",                                        
    :version => "1.1",                                                     
    :link    => "https://www.pokecommunity.com/showthread.php?t=317142",             
    :credits => "FL"
  })
end

class CatchGameScene
  # The number of positions or columns for the balls/player
  COLUMNS=7
  
  # The speed of the ball in pixels per frame
  BALL_SPEED=8
  
  # Max distance allowed between balls
  MAX_DISTANCE=1
  
  # The line/ball proportion
  LINE_PER_BALL=3.0
  
  # The number of frames until the next value of @lineArray
  FRAMES_PER_LINE=12
  
  # Player sprite speed. Lower = move faster. 1 = Instant move
  PLAYER_FRAMES_TO_MOVE=4
  
  X_START=56
  Y_START=-40
  X_GAIN=64
  
  def pbStartScene(balls)
    @sprites={} 
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap("Graphics/Pictures/backgroundcatch")
    @sprites["background"].x=(Graphics.width-@sprites["background"].bitmap.width)/2
    @sprites["background"].y=(Graphics.height-@sprites["background"].bitmap.height)/2
    @sprites["player"]=IconSprite.new(0,0,@viewport)
    @sprites["player"].setBitmap("Graphics/Pictures/catcher")
    @sprites["player"].y=340-@sprites["player"].bitmap.height/2
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @balls=balls
    initializeBallsPositions
    @frameCount=-1
    @playerColumn=COLUMNS/2
    @playerPosition = playerColumnPosition(@playerColumn)
    refreshPlayerPosition
    @score=0
    @pickSE="Player jump"
    @pickSE="jump" if !pbResolveAudioSE(@pickSE) # Compatibility with older versions
    @outSE="Battle ball drop"
    @outSE="balldrop" if !pbResolveAudioSE(@outSE) # Compatibility with older versions
    pbDrawText
    pbBGMPlay("021-Field04")
    pbFadeInAndShow(@sprites) { update }
  end

  def pbDrawText
    overlay=@sprites["overlay"].bitmap
    overlay.clear 
    score=_INTL("Score: {1}/{2}",@score,@balls)    
    baseColor=Color.new(248,248,248)
    shadowColor=Color.new(112,112,112)
    textPositions=[[score,8,2,false,baseColor,shadowColor]]
    pbDrawTextPositions(overlay,textPositions)
  end
  
  def updatePlayerPosition
    targetPosition = playerColumnPosition(@playerColumn)
    return if @playerPosition == targetPosition
    gain = X_GAIN/PLAYER_FRAMES_TO_MOVE.to_f
    if targetPosition>@playerPosition
      @playerPosition=[@playerPosition+gain, targetPosition].min
    else
      @playerPosition=[@playerPosition-gain, targetPosition].max
    end
    refreshPlayerPosition
  end
      
  def refreshPlayerPosition
    @sprites["player"].x=@playerPosition-@sprites["player"].bitmap.width/2
  end
      
  def playerColumnPosition(column)
    return X_START+X_GAIN*column
  end 
  
  def update
    pbUpdateSpriteHash(@sprites)
  end
  
  def initializeBall(position)
    i=0
    # This method reuse old balls for better performance
    loop do
      if !@sprites["ball#{i}"]
        @sprites["ball#{i}"]=IconSprite.new(0,0,@viewport)
        @sprites["ball#{i}"].setBitmap("Graphics/Pictures/ballcatch")
        @sprites["ball#{i}"].ox=@sprites["ball#{i}"].bitmap.width/2
        @sprites["ball#{i}"].oy=@sprites["ball#{i}"].bitmap.height/2
        break
      end  
      if !@sprites["ball#{i}"].visible
        @sprites["ball#{i}"].visible=true
        break
      end
      i+=1
    end
    @sprites["ball#{i}"].x=X_START+X_GAIN*position
    @sprites["ball#{i}"].y=Y_START
  end  
   
  def initializeBallsPositions
    lines=(LINE_PER_BALL*@balls).floor
    @lineArray=[]
    @lineArray[lines-1]=nil # One position for every line
    loop do
      while @lineArray.nitems<@balls
        ballIndex = rand(lines)
        @lineArray[ballIndex] = rand(COLUMNS) if !@lineArray[ballIndex]
      end  
      for i in 0...@lineArray.size
        next if !@lineArray[i]
        # Checks if the ball isn't too distant to pick.
        # If is, remove from the array
        checkRight(i+1,@lineArray[i]+MAX_DISTANCE)
        checkLeft(i+1,@lineArray[i]-MAX_DISTANCE)
      end
      return if @lineArray.nitems==@balls
    end
  end  
  
  def checkRight(index, position)
    return if (position>=COLUMNS || index>=@lineArray.size)
    if (@lineArray[index] && @lineArray[index]>position)
      @lineArray[index]=nil
    end
    checkRight(index+1,position+MAX_DISTANCE)
  end  
  
  def checkLeft(index, position)
    return if (position<=0 || index>=@lineArray.size)
    if (@lineArray[index] && @lineArray[index]<position)
      @lineArray[index]=nil
    end
    checkLeft(index+1,position-MAX_DISTANCE)
  end  
  
  def applyCollisions
    i=0
    loop do
      break if !@sprites["ball#{i}"]
      if @sprites["ball#{i}"].visible
        @sprites["ball#{i}"].y+=BALL_SPEED
        @sprites["ball#{i}"].angle+=10
        ballBottomY = @sprites["ball#{i}"].y+@sprites["ball#{i}"].bitmap.height
       
        # Collision with player
        ballPosition=(@sprites["ball#{i}"].x-X_START+
            @sprites["ball#{i}"].bitmap.width/2)/X_GAIN
        if ballPosition==@playerColumn
          collisionStartY=-8 
          collisionEndY=10
          # Based at target center
          playerCenterY=@sprites["player"].y+@sprites["player"].bitmap.width/2
          collisionStartY+=playerCenterY
          collisionEndY+=playerCenterY
          if(collisionStartY < ballBottomY && collisionEndY > ballBottomY)
            # The ball was picked  
            @sprites["ball#{i}"].visible=false
            pbSEPlay(@pickSE)
            @score+=1
            pbDrawText # Update score at screen
          end
        end
        
        # Collision with screen limit
        screenLimit = Graphics.height+@sprites["ball#{i}"].bitmap.height
        if(ballBottomY>screenLimit)
          # The ball was out of screen 
          @sprites["ball#{i}"].visible=false
          pbSEPlay(@outSE)
        end
      end  
      i+=1
    end
  end  
  
  def thereBallsInGame?
    i=0
    loop do
      return false if !@sprites["ball#{i}"]
      return true if @sprites["ball#{i}"].visible
      i+=1
    end
  end  
    
  def pbMain
    stopBalls = false
    loop do
      @frameCount+=1
      applyCollisions
      indexNextBall=@frameCount/FRAMES_PER_LINE
      stopBalls = indexNextBall>=@lineArray.size
      if @frameCount%FRAMES_PER_LINE==0 && !stopBalls && @lineArray[indexNextBall]
        initializeBall(@lineArray[indexNextBall])
      end
      Graphics.update
      Input.update
      self.update
      if stopBalls && !thereBallsInGame?
        Kernel.pbMessage(_INTL("Game end!"))
        break
      end  
      if Input.repeat?(Input::LEFT) && @playerColumn>0
        @playerColumn=@playerColumn-1
      end
      if Input.repeat?(Input::RIGHT) && @playerColumn<(COLUMNS-1)
        @playerColumn=@playerColumn+1
      end
      updatePlayerPosition
    end
    return @score
  end

  def pbEndScene
    $game_map.autoplay
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end
  
class Array
  def nitems
    count{|x| !x.nil?}
  end
end unless Array.method_defined?(:nitems)

class CatchGame
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen(balls)
    @scene.pbStartScene(balls)
    ret=@scene.pbMain
    @scene.pbEndScene
    return ret
  end
end

def pbCatchGame(balls=50)
  ret = nil
  pbFadeOutIn(99999) { 
    scene=CatchGameScene.new
    screen=CatchGame.new(scene)
    ret = screen.pbStartScreen(balls)
  }
  return ret
end