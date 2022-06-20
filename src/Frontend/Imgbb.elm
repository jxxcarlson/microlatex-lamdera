module Frontend.Imgbb exposing (track, uploadNextFile)

{-| Upload an image using Imgbb service and track progress.
Typical response after a successul upload is:
{
"data": {
"url": "<https://i.ibb.co/6NMDgSB/sample.jpg">,
"width": "2333",
"height": "3500",
...
},
"success": true,
"status": 200
}
See <https://api.imgbb.com> for the full API documentation.
-}

import Duration
import Effect.Command exposing (Command, FrontendOnly)
import Effect.File
import Effect.Http
import File exposing (File)
import Http exposing (Error)
import Json.Decode as D exposing (Decoder)
import Types exposing (FrontendMsg(..), ImageData, ToBackend, UploadState(..))


endpointUrl =
    -- Set expiration to 180 days
    "https://api.imgbb.com/1/upload?expiration=15552000&key="


uploadTimeout =
    60 * 1000


uploadNextFile key files =
    case files of
        next :: others ->
            ( Uploading next others 0
            , postTo key next
            )

        [] ->
            ( Ready
            , Effect.Command.none
            )


postTo : String -> Effect.File.File -> Command FrontendOnly ToBackend FrontendMsg
postTo key file =
    Effect.Http.request
        { method = "POST"
        , headers = []
        , url = endpointUrl ++ key
        , body =
            Effect.Http.multipartBody
                [ Effect.Http.filePart "image" file
                ]
        , expect = Effect.Http.expectJson FileUploaded responseDecoder
        , timeout = Just (Duration.milliseconds uploadTimeout)
        , tracker = Just (Effect.File.name file)
        }


track current others =
    Effect.Http.track (Effect.File.name current) (FileUploading current others)


responseDecoder : Decoder ImageData
responseDecoder =
    D.map5 ImageData
        (D.at [ "data", "url" ] D.string)
        (D.succeed "")
        (D.map String.toInt (D.at [ "data", "width" ] D.string))
        (D.map String.toInt (D.at [ "data", "height" ] D.string))
        (D.at [ "data", "image", "mime" ] (D.maybe D.string))
