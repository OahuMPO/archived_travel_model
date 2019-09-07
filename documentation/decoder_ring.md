## Unlocking the mysteries in categorical data coded as integers

Without a doubt one of the most egregiously incompetent practices in transport planning is the coding of categorical data using integers in survey data and synthetic travel diaries. The useability and portability of the OahuMPO V6 modeling system and supporting data are badly crippled by this, and compounded by the difficulty of finding their definitions. We will attempt to fill that gap by collecting such definitions in this file for easy reference. Please cite the specific location of where you eventually find the definitions in the writeups that follow. Finally, if you're not great at coding tables in Markdown on the fly please enter the data in this [excellent online table generator](https://www.tablesgenerator.com/markdown_tables) and then paste the creation below.

Several references will be used often and can be cited by acronyms:

+ FMR: Final Model Refresh Report, July 2013
+ TBTME: Tour-Based Travel Model Estimation for Oahu Metropolitan Planning Organization, June 2013
+ UGPM: User's Guide for the OahuMPO Planning Model in TransCAD 6.0, June 2013
+ OHTS: Oahu Household Travel Survey: Final Report, February 2013

### Time period definitions

The V6 resident tour-based model simulation clock begins at 0300 and ends at 0259 the following morning. Trips are scheduled in 30-minute bins sequentially numbered from 1-48, giving rise to the following equivalencies:

| Acronym | Description    | Hours     | periods  |
|---------|----------------|-----------|----------|
| EA      | Early morning  | 0300-0559 | 1-6      |
| AM      | AM peak period | 0600-0859 | 7-12     |
| MD      | Mid-day period | 0900-1459 | 13-24    |
| PM      | PM peak period | 1500-1859 | 25-32    |
| NT      | Nighttime      | 1900-0259 | 0, 33-48 |

Summarizing these data by period is straightforward. However, if you want to create hourly distributions you'll find that there are in fact 49 levels in the `period` variable in trip records. A value of zero denotes a trip in motion when the simulation begins. There are not many of these in the data, but they can be assigned to the 0200 (2 AM) hour. Since the periods are numbered sequentially from 0300 their conversion to starting hour requires a little more work. The following code will develop an equivalency table in R that can then be merged with the trip list by `period`:

```{r}
repeater <- c(2)  # Trips already in motion start in this hour
for (hour in 0:23) { repeater <- c(repeater, hour); repeater <- c(repeater, hour) }
temporal_offsets <- tibble(hour = repeater, period = c(0, 43:48, 1:42))
```

### Origin and destination purpose

The activities at the origin and destination can be used to classify trips (tour segments) by traditional home-based and non-home-based trip purposes. These data are coded as `originPurpose` and `destinationPurpose` in the trip list built from tour lists, as well as `ORIG_PURP` and `DEST_PURP` in some of the model estimation scripts and data files. There are eight levels associated with these variables, ranging from -1 to 6. However, there is no reference anywhere to what these integer indices correspond to. Both are of course defined in the 2012 Household Travel Survey data and documentation used to build the model, but they used 27 definitions (see OHTS pp. 93-94) that were apparently condensed to the eight values used in the model. The code that made the translations is not found in the project archives, nor is an equivalency table found anywhere in the documentation. One can only include that the omission was intentional, or that their definition was systematically removed from the archives before we started on the project.

(The trip records are also devoid of any information about tour purpose, or even broad classification such as mandatory or discretionary. I've never come across a travel model where such information is not coded on corresponding trip records, but we'll leave discussion of that for another time.)

About two-thirds of the trip records have -1, which is often used to portably code missing values, coded for either origin or destination purpose. Curiously, none have that coded for both purposes. Cross-tabulating these variables with `firstOrigin` and `lastDestination` variables on the trip record revealed that -1 is coded for the tour origin, which since is the household the traveler belongs to since all tours coded in the model are closed (i.e., begin and end at home). Thus, -1 can be replaced with a 'home' label.

The remaining seven values are still somewhat of a mystery. There are 10 stop purposes coded for stop frequency and location models (see Table 28 on page 82 of the _Final . Moreover, they're reasons for stopping, which is subtly different from the activity undertaken at the stop location.
