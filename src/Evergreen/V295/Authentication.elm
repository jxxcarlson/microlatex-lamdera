module Evergreen.V295.Authentication exposing (..)

import Dict
import Evergreen.V295.Credentials
import Evergreen.V295.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V295.User.User
    , credentials : Evergreen.V295.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
