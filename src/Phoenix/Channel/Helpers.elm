module Phoenix.Channel.Helpers exposing (assignResponseType) -- where
{-| Helpers

Convert your response type from a string to a message
@docs assignResponseType

-}
import Json.Decode exposing (decodeString)
import Phoenix.Channel.Model exposing (decodeSocketMessage, SocketMessage)
import Phoenix.Channel.Update exposing (Msg(..))


turnDecodedResponseIntoServerResponse : Result String SocketMessage -> Msg
turnDecodedResponseIntoServerResponse response =
  case response of
    Ok socketResponse ->
      case socketResponse.payload.status of
        "ok" ->
          SuccessfulResponse socketResponse
        _ ->
          ErrorResponse (socketResponse.payload.status)
    Err message ->
      ErrorResponse message

{-| Converts a string into a Msg
-}
assignResponseType : String -> Msg
assignResponseType =
    decodeString decodeSocketMessage
      >> turnDecodedResponseIntoServerResponse
