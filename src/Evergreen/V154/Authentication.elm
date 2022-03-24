module Evergreen.V154.Authentication exposing (..)

import Dict
import Evergreen.V154.Credentials
import Evergreen.V154.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V154.User.User
    , credentials : Evergreen.V154.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
