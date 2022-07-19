module Evergreen.V712.Compiler.DifferentialParser exposing (..)

import Evergreen.V712.Compiler.AbstractDifferentialParser
import Evergreen.V712.Compiler.Acc
import Evergreen.V712.Parser.Block
import Evergreen.V712.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V712.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V712.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V712.Parser.Block.ExpressionBlock) Evergreen.V712.Compiler.Acc.Accumulator
