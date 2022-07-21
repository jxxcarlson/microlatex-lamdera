module Token exposing (get)

import Random exposing (step)
import Uuid


get : Random.Seed -> { token : String, seed : Random.Seed }
get seed_ =
    let
        ( newUuid, newSeed ) =
            step Uuid.uuidGenerator seed_
    in
    { token = Uuid.toString newUuid, seed = newSeed }
