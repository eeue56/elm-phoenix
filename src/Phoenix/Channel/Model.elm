module Phoenix.Channel.Model exposing (
  Response, ResponsePayload, SocketMessage, MessageToSend
  , encodeMessageToSend, decodeSocketMessage
  , Model) -- where

{-| Types used for representing things that come from a phoenix channel

Our model used in our Program components
@docs Model

Dealing with server responses
@docs decodeSocketMessage
@docs SocketMessage, ResponsePayload, Response

Sending stuff to the server
@docs encodeMessageToSend
@docs MessageToSend
-}

import Json.Encode
import Json.Decode exposing (..)
import Json.Decode.Pipeline as Pipeline

{-| A response from the server
-}
type alias Response =
  { reason : String }

{-| The status of the response paired with the response itself
-}
type alias ResponsePayload =
  { status : String
  , response : Response
  }

{-| Each socket response has the topic (room) as a string, along with a ref count
    the event to trigger, and the payload of what the server actually sent
-}
type alias SocketMessage =
  { topic : String
  , ref : Int
  , payload : ResponsePayload
  , event : String
  }

{-| Like a socket message, but comes with a pre-encoded payload
-}
type alias MessageToSend =
  { topic : String
  , ref : Int
  , payload : Json.Encode.Value
  , event : String
  }

{-| We demand that any model must store the socket events, the current refNumber, and
the state of connection
-}
type alias Model a =
  { a
  | socketEvents : List SocketMessage
  , refNumber : Int
  , connected : Bool
  , socketUrl : String
  }


maybeNull : Decoder a -> Decoder (Maybe a)
maybeNull decoder =
  Json.Decode.oneOf [ Json.Decode.null Nothing, Json.Decode.map Just decoder ]

decodeRef : Decoder Int
decodeRef =
  Json.Decode.map (Maybe.withDefault -1) (maybeNull Json.Decode.int)

decodeResponse : Decoder Response
decodeResponse =
  Pipeline.decode Response
    |> Pipeline.optional "reason" (string) "NULL"

decodeResponsePayload : Decoder ResponsePayload
decodeResponsePayload =
  Pipeline.decode ResponsePayload
    |> Pipeline.required "status" (string)
    |> Pipeline.optional "response" decodeResponse ({ reason = ""})


{-| Decode a socket response.
-}
decodeSocketMessage : Decoder SocketMessage
decodeSocketMessage =
  Pipeline.decode SocketMessage
    |> Pipeline.required "topic" (string)
    |> Pipeline.optional "ref" decodeRef (-1)
    |> Pipeline.required "payload" (decodeResponsePayload)
    |> Pipeline.required "event" (string)

{-| Encode a message to send
-}
encodeMessageToSend : MessageToSend -> Json.Encode.Value
encodeMessageToSend message =
  Json.Encode.object
    [ ("topic", Json.Encode.string message.topic)
    , ("ref", Json.Encode.int message.ref)
    , ("payload", message.payload)
    , ("event", Json.Encode.string message.event)
    ]
