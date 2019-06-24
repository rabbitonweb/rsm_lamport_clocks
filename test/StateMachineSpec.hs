
module StateMachineSpec where

import StateMachine
import Control.Monad.State
import Test.Hspec
import Test.QuickCheck

main :: IO ()
main = hspec spec

spec :: Spec
spec = describe "machine" $ do
  it "applies commands correctly" $ do
    (execState (machine (Add 5) >> machine (Mult 2)) 0) `shouldBe` 10
  it "applying the same series of commands yields the same result" $ do
    property (\events -> (run $ apply events) `shouldBe` (run $ apply events))
  describe "serialization" $ do
    it "does roundtrip correctly" $ do
      property (\event -> (deserialize . serialize $ event) `shouldBe` event)

  describe "tick" $ do
    it "sets current time greater or equal current value if incoming external command's Tm is smaller" $ do
      forAll externalCommandGen (\extCmd @ (ExternalCommand externalClock cmd) currentTime -> execState (tick extCmd) currentTime `shouldBe` if(externalClock < currentTime) then currentTime else externalClock + 1)
    it "bumps the clock by 1 if incoming command is internal" $ do
      let currentTime = 2
      forAll internalCommandGen (\cmd -> execState (tick cmd) 1 `shouldBe` 2)

apply :: [Command] -> State TheState [()]
apply cmds = traverse machine cmds

run :: State TheState a -> Int
run s = execState s 0

instance Arbitrary Command where
  arbitrary = do
    i <- choose(0, 100)
    elements[Add i, Mult i]

internalCommandGen = do
    cmd <- arbitrary
    elements[(InternalCommand cmd)]

externalCommandGen = do
    clock <- arbitrary
    cmd <- arbitrary
    elements[(ExternalCommand clock cmd)]

instance Arbitrary IncomingCommand where
  arbitrary = oneof [internalCommandGen, externalCommandGen]
