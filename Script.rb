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

class CatchGameScene
  def update
    pbUpdateSpriteHash(@sprites)
  end
  
  def pbStartScene(balls)
    @sprites={} 
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap("Graphics/Pictures/backgroundcatch")
    @sprites["background"].x=(
        Graphics.width-@sprites["background"].bitmap.width)/2
    @sprites["background"].y=(
        Graphics.height-@sprites["background"].bitmap.height)/2
    @sprites["player"]=IconSprite.new(0,0,@viewport)
    @sprites["player"].setBitmap("Graphics/Pictures/catcher")
    @sprites["overlay"]=BitmapSprite.new(
        Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @balls=balls
    initializeBallsPositions
    @frameCount=-1
    @playerPosition=POSITIONS/2
    updatePlayerPosition
    @score=0
    pbDrawText
    pbBGMPlay("021-Field04")
    pbFadeInAndShow(@sprites) { update }
  end

  def pbDrawText
    overlay=@sprites["overlay"].bitmap
    overlay.clear 
    score=_INTL("Score: {1}/{2}",@score,@balls)
    baseColor=Color.new(72,72,72)
    shadowColor=Color.new(160,160,160)
    textPositions=[
       [score,8,2,false,baseColor,shadowColor],
    ]
    pbDrawTextPositions(overlay,textPositions)
  end
  
  YSTART=-40
  XSTART=56
  XGAIN=64
  
  def updatePlayerPosition
    @sprites["player"].x=(
        XSTART+XGAIN*@playerPosition-@sprites["player"].bitmap.width/2)
    @sprites["player"].y=340-@sprites["player"].bitmap.height/2
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
    @sprites["ball#{i}"].x=XSTART+XGAIN*position
    @sprites["ball#{i}"].y=YSTART
  end  
  
  POSITIONS=7 # The number of positions or columns for the balls/player
  LINEPERBALL=3.0 # The line/ball proportion
  FRAMESPERLINE=12 # The number of frames until the next value of @lineArray
  BALLSPEED=8 # The speed of the ball in pixels per frame
  MAXDISTANCE=1 # Max distance allowed between balls
   
  def initializeBallsPositions
    lines=(LINEPERBALL*@balls).floor
    @lineArray=[]
    @lineArray[lines-1]=nil # One position for every line
    loop do
      while @lineArray.nitems<@balls
        ballIndex = rand(lines)
        @lineArray[ballIndex] = rand(POSITIONS) if !@lineArray[ballIndex]
      end  
      for i in 0...@lineArray.size
        next if !@lineArray[i]
        # Checks if the ball isn't too distant to pick.
        # If is, remove from the array
        checkRight(i+1,@lineArray[i]+MAXDISTANCE)
        checkLeft(i+1,@lineArray[i]-MAXDISTANCE)
      end
      return if @lineArray.nitems==@balls
    end
  end  
  
  def checkRight(index, position)
    return if (position>=POSITIONS || index>=@lineArray.size)
    if (@lineArray[index] && @lineArray[index]>position)
      @lineArray[index]=nil
    end
    checkRight(index+1,position+MAXDISTANCE)
  end  
  
  def checkLeft(index, position)
    return if (position<=0 || index>=@lineArray.size)
    if (@lineArray[index] && @lineArray[index]<position)
      @lineArray[index]=nil
    end
    checkLeft(index+1,position-MAXDISTANCE)
  end  
  
  def applyCollisions
    i=0
    loop do
      break if !@sprites["ball#{i}"]
      if @sprites["ball#{i}"].visible
        @sprites["ball#{i}"].y+=BALLSPEED
        @sprites["ball#{i}"].angle+=10
        ballBottomY = @sprites["ball#{i}"].y+@sprites["ball#{i}"].bitmap.height
       
        # Collision with player
        ballPosition=(@sprites["ball#{i}"].x-XSTART+
            @sprites["ball#{i}"].bitmap.width/2)/XGAIN
        if ballPosition==@playerPosition
          collisionStartY=-8 
          collisionEndY=10
          # Based at target center
          playerCenterY=@sprites["player"].y+@sprites["player"].bitmap.width/2
          collisionStartY+=playerCenterY
          collisionEndY+=playerCenterY
          if(collisionStartY < ballBottomY && collisionEndY > ballBottomY)
            # The ball was picked  
            @sprites["ball#{i}"].visible=false
            pbSEPlay("jump")
            @score+=1
            pbDrawText # Update score at screen
          end
        end
        
        # Collision with screen limit
        screenLimit = Graphics.height+@sprites["ball#{i}"].bitmap.height
        if(ballBottomY>screenLimit)
          # The ball was out of screen 
          @sprites["ball#{i}"].visible=false
          pbSEPlay("balldrop")
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
      indexNextBall=@frameCount/FRAMESPERLINE
      stopBalls = indexNextBall>=@lineArray.size
      if (@frameCount%FRAMESPERLINE==0 && !stopBalls &&
          @lineArray[indexNextBall])
        initializeBall(@lineArray[indexNextBall])
      end
      Graphics.update
      Input.update
      self.update
      if stopBalls && !thereBallsInGame?
        Kernel.pbMessage(_INTL("Game end!"))
        break
      end  
      if Input.repeat?(Input::LEFT) && @playerPosition>0
        @playerPosition=@playerPosition-1
        updatePlayerPosition
      end
      if Input.repeat?(Input::RIGHT) && @playerPosition<(POSITIONS-1)
        @playerPosition=@playerPosition+1
        updatePlayerPosition
      end
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
  scene=CatchGameScene.new
  screen=CatchGame.new(scene)
  return screen.pbStartScreen(balls)
end