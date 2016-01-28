module Ev3Dashboard where

import Html exposing (..)
import StartApp
import Html.Attributes exposing (class, attribute)
import Effects exposing (Effects, Never)
import Task exposing (Task)

import Ev3Status exposing (StatusAction (Status))

type alias Action =
            StatusAction
                   
type alias Model = {status: Ev3Status.Model
                   }


app : StartApp.App Model
app =
  StartApp.start
          {init = init
           , update = update
           , view = view
           , inputs = inputs
          }

main : Signal Html
main =
  app.html

-- MODEL

init: (Model, Effects Action)
init =
  ({status = Ev3Status.initModel
   },
   Effects.batch([Ev3Status.initEffect
                 ]))

-- VIEW

view: Signal.Address Action -> Model -> Html
view address model =
  div[class "container-fluid", attribute "role" "main"]
     [Ev3Status.view address model.status
     ]
 
-- UPDATE

-- UPDATE

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    Status a ->
      let
        (newStatus, effects) = Ev3Status.update a model.status
      in
        ({ model | status = newStatus}, effects)

-- PORTS

port tasks : Signal (Task Never ()) 
port tasks =
  app.tasks -- From effects

  -- Status ports

port runtimeStats : Signal Ev3Status.RuntimeStats -- From channels

-- INPUTS

inputs: List (Signal Action)
inputs =
  [statusInputs
  ]

  -- Status inputs

statusInputs: Signal StatusAction
statusInputs =
  Signal.map Status <| Signal.map Ev3Status.SetRuntimeStats runtimeStats