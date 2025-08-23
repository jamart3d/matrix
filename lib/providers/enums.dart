// lib/providers/enums.dart

/// Defines the sort order for the list of shows.
enum ShowSortOrder { dateDescending, dateAscending }

/// Defines the visibility behavior of the year scrollbar on the Shows page.
enum YearScrollbarBehavior { onScroll, always, off }

/// Defines the overall color palette for the Matrix Rain page.
enum MatrixColorTheme { classicGreen, cyanBlue, purpleMatrix, redAlert, goldLux }

/// Defines how the colors are applied to the title characters in the Matrix Rain.
enum MatrixTitleStyle { random, gradient, solid }

/// Defines the appearance of the random, non-title "filler" characters.
enum MatrixFillerStyle { dimmed, themed, invisible }

/// Defines the base color for the "Dimmed" filler style.
enum MatrixFillerColor { defaultGray, green, cyan, purple, red, gold, white }

/// Defines which page the application opens to on startup.
enum StartupPage { shows, albums, matrix }

/// Defines the brightness of the glow effects on the Matrix Rain page.
enum MatrixGlowIntensity { half, normal, double }

/// Defines the color of the leading (brightest) character in a Matrix Rain column.
enum MatrixLeadingColor { white, green, cyan, purple, red, gold }

/// Defines the animation style for the falling text in the Matrix Rain.
enum MatrixStepMode { smooth, stepped, chunky }

/// Defines the horizontal spacing between columns in the Matrix Rain.
enum MatrixLaneSpacing { standard, tight, overlap }

/// Defines the size of the Floating Action Button on the Shows and Matrix pages.
enum FabSize { normal, large }

/// Defines the font weight for characters in the Matrix Rain.
enum MatrixFontWeight { normal, bold }

/// Defines the font size for characters in the Matrix Rain.
enum MatrixFontSize { small, medium, large }