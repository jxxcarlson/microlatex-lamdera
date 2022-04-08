module Evergreen.V286.Authentication exposing (..)

import Dict
import Evergreen.V286.Credentials
import Evergreen.V286.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V286.User.User
    , credentials : Evergreen.V286.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
