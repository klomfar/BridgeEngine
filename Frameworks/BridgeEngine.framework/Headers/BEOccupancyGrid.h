/*
 This file is part of the Structure SDK.
 Copyright © 2018 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#pragma once
#import <BridgeEngine/BridgeEngineAPI.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM (NSUInteger, BEOccupancy) {
    /// No map data is available at this location.
    Unknown = 0,
    
    /// The floor was detected here.
    Floor = 1,
    
    /// There is an object which is no lower than 0.5 meters
    Covered = 1 << 1,
    
    /// There is an object within the range 0.05 and 0.5 meters
    Obstacle = 1 << 2,
};

BE_API
@interface BEOccupancyGrid: NSObject

/**
 BEOccupancyGrid uses a bitmask image representation to represent several states with one pixel
 Please reference the BEOccupancy enum above for the default values
 
 If the value is changed the new value must be between 0 and 255
*/

/** Initializes new Occupancy Grid.
 */
- (instancetype)init;

/** Loads the default bitmask grid from disk.
 
 @param gridPath - the full path of the grid saved on the disk.
 - default file name: occupancy_grid.png
 @param metaDataPath - the full path of the metadata for the grid.
 - default file name: occupancy_grid_metadata.json
 */
- (BOOL)loadGridFromFilePath:(NSString*)gridPath metaDataPath:(NSString*)metaDataPath;

/** Returns the position of the center of pixel (0, 0) along the x-axis in meters.
    Use ((xPoseInMeters * metersPerPixel) + originX) to get the x pixel value for a given pose
 */
- (float)originX;

/** Returns the position of the center of pixel (0, 0) along the y-axis in meters.
    Use ((yPoseInMeters * metersPerPixel) + originY) to get the y pixel value for a given pose
 */
- (float)originY;

/** Returns the meters represented by each grid pixel.
 */
- (float)metersPerPixel;

/** Returns the width of the grid in pixels.
 */
- (int)width;

/** Returns the height of the grid in pixels.
 */
- (int)height;

/** Returns the value of a grid pixel (0-255).
 
 @param x - collumn index of pixel
 @param y - row index of pixel
 */
- (int)getPixelAtXIndex:(int)x yIndex:(int)y;

/** Sets the value of a grid pixel (0-255) and returns the set success.
 
 @param x - column index of pixel
 @param y - row index of pixel
 @param value - value to set pixel to
 */
- (bool)setPixelAtXIndex:(int)x yIndex:(int)y toValue:(int)value;

/** Convert the grid so that all pixels represeting the floor are set to 255.

 @param inGrid - loaded using LoadGridFromFile
 @param outGrid - to load the new floor grid in to
*/
+ (void)convertToFloorGrid:(BEOccupancyGrid*)inGrid outputGrid:(BEOccupancyGrid*)outGrid;

/** Convert the grid so that all pixels represeting a covered area are set to 255.
 
 @param inGrid - loaded using LoadGridFromFile
 @param outGrid - to load the new covered grid in to
*/
+ (void)convertToCoveredGrid:(BEOccupancyGrid*)inGrid outputGrid:(BEOccupancyGrid*)outGrid;

/** Convert the grid so that all pixels represeting an obstacle are set to 255.
 
 @param inGrid - loaded using LoadGridFromFile
 @param outGrid - to load the new obstacle grid in to
 */
+ (void)convertToObstacleGrid:(BEOccupancyGrid*)inGrid outputGrid:(BEOccupancyGrid*)outGrid;

@end
