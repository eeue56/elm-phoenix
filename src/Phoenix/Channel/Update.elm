module Phoenix.Channel.Update exposing (update, Msg(..)) -- where
{-|

The possible messages from the server
@docs Msg

The update function for dealing with that
@docs update
-}
import Json.Encode
import WebSocket
import Phoenix.Channel.Model exposing (..)

{-|
  - SuccessfulResponse is only triggered when "ok" is the status
  - ErrorResponse is everything else
-}
type Msg
  = SuccessfulResponse SocketMessage
  | ErrorResponse String
  | SendMessage MessageToSend


{-| Take a msg from a channel, and update the model based on the msg recieved
-}
update : Msg -> Model a -> (Model a, Cmd Msg)
update response model =
  case response of
    ErrorResponse string ->
      let
        _ =
          Debug.log "Error from websocket: " string
      in
        (model, Cmd.none)

    SuccessfulResponse message ->
      ( addEvent message model, Cmd.none )

    SendMessage message ->
      model ! [ send model message ]



send : Model a -> MessageToSend -> Cmd msg
send model message =
  encodeMessageToSend message
    |> Json.Encode.encode 0
    |> WebSocket.send model.socketUrl


addEvent : SocketMessage -> Model a -> Model a
addEvent message model =
  let
    payload =
      message.payload

    status =
      payload.status
  in
    case status of
      "ok" ->
        { model
          | refNumber = model.refNumber + 1
          , connected = True
          , socketEvents = (message :: model.socketEvents)
        }

      _ ->
        model
