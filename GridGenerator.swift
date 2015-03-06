//
//  GridGenerator.swift
//  LearnBricks
//
//  Created by murzeg on 12/01/15.
//  Copyright (c) 2015 rooty.net All rights reserved.
//

import Foundation

class GridGenerator
{
    // Const
    let SENTENCES_PARTICIPATING_COUNT   = 7;// tiles count in 4x4 grid
    let DISTRACTING_TILES_COUNT         = 5;
    let MAX_ATTEMPTS_COUNT              = 5000;
    
    // Props
    var gridSize:Int?;
    
    
    // Computed props
    var columnsCount: Int
    {
        if( self.gridSize == 16 )
        {
            return 4;
        }
        else
        {
            return 5;
        }
    }
    
    // Construct
    init()
    {}
    
    /// Generates grid using required parameters
    ///
    func generateGrid( initialWords:QuizletTermsSet, gridMetrics:Int, twoPlayerMode:Bool = false, prepopulatedGrid:GridModel? ) -> ( grid: GridModel, clues: CluesListModel )?
    {
        // Just generate grid rows for the view
        if let grid = prepopulatedGrid
        {
            self.createGridRows( grid );
            
            println( "ViewGrid rows created" );
            
            return nil;
        }
        else
        {
            // set required gridSize
            self.gridSize = gridMetrics;
        
            var collisionInGrid:Bool = true;
        
            // generate grid in a loop until there won't be found any collisions
            
            var words:[ QuizletTerm ];
            var grid:GridModel;
            var cluesList:CluesListModel;
            
            do
            {
                // make a clone of the words object
                words = initialWords.terms;
                grid = GridModel();
                cluesList = CluesListModel();
                
                grid.gridTileStacks = self.generateTileStacks( gridMetrics );
                
                
                // nested func for convenience
                func getRandomWord( inout inputWords:[ QuizletTerm ] ) -> QuizletTerm?
                {
                    if inputWords.count > 0
                    {
                        var randomWordIndex = Int( arc4random_uniform( UInt32( inputWords.count) ) );
                        var randomWordOutput:QuizletTerm = inputWords[ randomWordIndex ];
                        
                        words.removeAtIndex( randomWordIndex );
                        
                        return randomWordOutput;
                    }
                    else
                    {
                        println( "Not enough words to create grid!" );
                        return nil;
                    }
                }
                
                // Create all participating words (sentences) list
                var participatingWordsList:[ QuizletTerm ] = [];
                
                var currentWord:QuizletTerm?;
                
                collisionInGrid = false;
                
                for var n = 0 ; participatingWordsList.count < SENTENCES_PARTICIPATING_COUNT ; ++n
                {
                    // get random word
                    currentWord = getRandomWord( &words );
                    
                    if var tempCurrentWord = currentWord
                    {
                        participatingWordsList.append( tempCurrentWord );
                    }
                    else
                    {
                        collisionInGrid = true;
                        
                        println( "currentWord is null" );
                        break;
                    }
                }
                
                // skip the remaining execution if there was not enough words to create grid
                if collisionInGrid
                {
                    continue
                }
                
                var distractingTilesList = self.generateDistractingTilesList( words, participatingWordsList: participatingWordsList );
                
                
                var randomDistractingTileIndex:Int;
                var currentTile:TileModel;
                
                // adding distracting tiles to the most bottom layer
                for n in 0...gridMetrics
                {
                    randomDistractingTileIndex = Int( arc4random_uniform( UInt32( distractingTilesList.count) ) );
                    
                    // TODO: get cloned distracting tiles from the list ( ADD .clone() method )
                    currentTile = distractingTilesList[ randomDistractingTileIndex ];
                    
                    grid.addTileAtPosition( currentTile, position: n );
                }
                
                var currentClue:ClueModel;
                var wordsTilesList:[ TileModel ];
                
                for currentWord in participatingWordsList
                {
                    // create Clue model
                    currentClue = ClueModel( word: currentWord.term, definition: currentWord.def );
                    
                    // create words tiles list, and provide Clue object for each tile word
                    wordsTilesList = self.generateWordsTilesList( currentClue );
                    
                    grid.addWordsTilesListToRandomPositions_Plus_AddDistractingTiles( wordsTilesList, distractingTilesList: distractingTilesList, distractingTilesCount:DISTRACTING_TILES_COUNT );
                    
                    // add current clue to the clues list
                    cluesList.addClue( currentClue );
                }
            }
            while collisionInGrid
            
            println( "Grid generation finished" );
            
            self.createGridRows( grid );
            
            println( "ViewGrid rows created" );
            
            // return just generated data as tuple
            return ( grid, cluesList );
        }
    }

    
    /// Generate empty tiles stacks for each cell in the grid
    ///
    func generateTileStacks( gridSize:Int ) -> [ TilesStack ]
    {
        var stack:[ TilesStack ] = [];
        
        for _ in 1...gridSize
        {
            stack.append( TilesStack() );
        }
        
        return stack;
    }

    
    /// Creates array of row arrays for the view representation of the grid
    ///
    func createGridRows( inputModel:GridModel ) -> [[ TilesStack ]]
    {
        var columnsCount:Int = self.columnsCount;
        var currentTile:TilesStack;
        
        var gridTileStacks:[ TilesStack ] = inputModel.gridTileStacks;
        var rowsArray:[[ TilesStack ]] = [];
        var currentRowArray:[ TilesStack ] = [];
        
        // arrange grid for the view
        for i in 0...gridTileStacks.count
        {
            currentTile = gridTileStacks[i];
            
            if i > 0 && i % columnsCount == 0
            {
                rowsArray.append( currentRowArray );
                
                currentRowArray = [];
            }
            
            currentRowArray.append( currentTile );
        }
        
        // add last row
        rowsArray.append( currentRowArray );
        
        
        // populate row and column properties
        for i in 0...rowsArray.count
        {
            for t in 0...rowsArray[i].count
            {
                currentTile = rowsArray[i][t];
                
                currentTile.row = i;
                currentTile.column = t;
            }
        }
        
        return rowsArray;
    }


    /// Generates words tiles list for the grid
    ///
    func generateWordsTilesList( currentClue:ClueModel ) -> [ TileModel ]
    {
        var output:[ TileModel ] = [];
        
        var wordsList:[ String ] = currentClue.wordsList;
        var currentWordTile:TileModel;
        
        for currentWord in wordsList
        {
            currentWordTile = TileModel( isDistractingTile: false, clue: currentClue, value: currentWord );
            
            output.append( currentWordTile );
        }
        
        return output;
    }



    /// Generate distracting tiles list using all the items inside of the Quizlet terms set,
    /// BUT EXCLUDE items used in the GAME.
    ///
    func generateDistractingTilesList( termsList:[ QuizletTerm ], participatingWordsList:[ QuizletTerm ] ) -> [ TileModel ]
    {
        var output:[ TileModel ] = [];
        var a:[ String ];
        
        for currentItem in termsList
        {
            a = currentItem.term.componentsSeparatedByString(" ");
            
            for subWord in a
            {
                output.append( TileModel( isDistractingTile: true, clue: nil, value: subWord ) );
            }
        }
        
        return output;
    }


}