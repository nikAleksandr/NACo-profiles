import processing.pdf.*;
PFont countyNameFont, numbers2015, graphNumbers, countyNumbers2015;
PShape template;
PImage infographic;
Table data;
int numRows, cr = 130; // current row

//set parameters for line graphs
int graph1X= 143, graph2X= graph1X + 220, graph3X= graph2X + 220; 
int graphY = 207;
int graphWidth = 185, graphHeight = 103;
int graphBeginYear = 1967, graphEndYear = 2015;

void setup() {
  size(792, 612);
  countyNameFont = createFont("MuseoSlab-500", 22);
  numbers2015 = createFont("BebasNeueRegular", 48);
  graphNumbers = createFont("Helvetica Neue Light", 7);
  countyNumbers2015 = createFont("BebasNeueRegular", 16);
  
  smooth();
  template = loadShape("template.svg");
  infographic = loadImage("infographic_EndangeredSpecies.png");
  
  //load data
  data = loadTable("data_final.tsv", "header");
  numRows = data.getRowCount();
 
}

void draw(){
  buildProfile();
  //cr++;
  if(cr==numRows) exit();
}

void buildProfile(){
 String countyName;
 int fips_num = data.getInt(cr, "FIPS_NUM");
   /*Get CountyNames by default and rename counties that need it*/
  switch(fips_num){
    case 20209:
      countyName = "Wyandotte County/Kansas City";
      break;
    case 21111:
      countyName = "Louisville/Jefferson County";
      break;
    case 22109:
      countyName = "Terrebonne Parish";
       break;
    case 47037:
      countyName = "Nashville/Davidson County";
      break; 
    case 2020:
      countyName = "Anchorage Borough";
      break;
    default:
      countyName = data.getString(cr, "County");
  }
  
  String stateName = data.getString(cr, "State");
  String fullCountyName = countyName + ", " + stateName;
  String fileName = countyName.replace(" ", "").replace(",", "") + stateName;
  beginRecord(PDF, "profiles/" + fileName + ".pdf");
  
  background(255);
  template.enableStyle();
  shape(template, 0, 0);
  image(infographic, 310, 346, 301, 188);
  
  //print CountyName to Profile
  textFont(countyNameFont);
  textAlign(LEFT, BOTTOM);
  fill(255);
  text(fullCountyName.toUpperCase(), 24, 107);

  YearLineGraph countyGraph;
  YearLineGraph stateGraph;
  YearLineGraph nationalGraph;
  
  countyGraph = new YearLineGraph(graph1X, graphY, graphWidth, graphHeight, "county_delistedstock_", "county_listedstock_",  graphBeginYear, graphEndYear, true);
  stateGraph = new YearLineGraph(graph2X, graphY, graphWidth, graphHeight, "delistedstock_", "listedstock_",  graphBeginYear, graphEndYear, true);
  nationalGraph = new YearLineGraph(graph3X, graphY, graphWidth, graphHeight, "national_delistings_", "national_listings_",  graphBeginYear, graphEndYear, true);
  
  numbers2015();
  countyNumbers2015(); 
}

class YearLineGraph {
  int xPos;
  int yPos;
  int w;
  int h;
  String var1_pre;
  String var2_pre;
  int yearStart;
  int yearEnd;
  boolean scaleStartAt0;
  
  //class constructor
  YearLineGraph(int xPos, int yPos, int w, int h, String var1_pre, String var2_pre, int yearStart, int yearEnd, boolean scaleStartAt0){
    //all linegraph variables must be formatted in the "variableNameYear" format to function, IE: "county_listedstock_1967"
    //Improvement - should allow the string var2_pre to be equal to "false"
    //improvement - make the text formatting, size, and offset dynamic with the overall size.
    //currently no ability to handle negative y values
    //improvement - add a unit parameter
    
    int xInterval=1, yMin=0, yMax=8, yRange, yInterval=1, yBaseLoc=yPos+h;
    int maxYLines = 8; //can adjust this parameter (and yMax) for more or less lines on the y axis
    boolean yLinesDrawn = false;
    
    //determine x range and scale (years)
    int yearSpan = yearEnd - yearStart;
    //determine xInterval - if the range is greater than 12, find a divisible xInterval.  If the range is a large prime number, explode.
    
    //determine y range and scale
      //find highest and lowest values among both indicators, or default lowest to 0 if scaleStartAt0 is true
      for(int i=yearStart; i<yearEnd+1; i++){
        String var1_temp = var1_pre + str(i);
        String var2_temp = var2_pre + str(i);
        
        Float var1_tempData = data.getFloat(cr, var1_temp);
        Float var2_tempData = data.getFloat(cr, var2_temp);
        
        //set an initial yMin value
        if(i==yearStart) yMin = int(var1_tempData);
        
        
        if(yMin > int(var1_tempData)) yMin = int(var1_tempData);
        if(yMin > int(var2_tempData)) yMin = int(var2_tempData);
        if(yMax < int(var1_tempData)) yMax = int(var1_tempData);
        if(yMax < int(var2_tempData)) yMax = int(var2_tempData); 
      }
      //if scaleStartAt0 is true, override the minimum value
        if(scaleStartAt0){
          yMin = 0;
        }
      
      //determine yRange
      yRange = yMax - yMin;
      //println("range: " + yRange + " yMax: " + yMax + " yMin: " + yMin );
      
      //determine yInterval (1, 5, 10, 25, 50, 100, 200, 500)  and yPerPx scale
        //the most y lines we want are 8
        //the PosYIntervals array sets possible intervals to try, starting with the default of 1.  It goes until maxYLines * posYInterval[v] is less than the yRange
      int[] posYIntervals = {1, 2, 5, 10, 25, 50, 100, 200, 500};
      int v = 0;
      while(yRange > posYIntervals[v]*maxYLines){
        v++;
        //println(yRange + " : " + posYIntervals[v] + " : " + maxYLines);
        yInterval = posYIntervals[v];
      }
      //move the yMax and yMin to the nearest next values that are divisible by the interval
      if(yMin % yInterval != 0){
        yMin -= yMin % yInterval; //subtract the remainder to get a divisible yMin
      }
      if(yMax % yInterval != 0){
        yMax += yInterval - (yMax % yInterval); //add what it takes to get a divisible yMax
      }
      
      //set scale of y based on pixel height and the full interval-divisible range
      yRange = yMax - yMin;
      float yPerPx = float(yRange) / float(h);
      float pxPerY = float(h) / float(yRange);
    
 
      
    //loop through the data and draw the line segment, xTic, and year text
      //find an divisible xInterval around 13
      if(yearSpan>13){
        xInterval+=1;
        while(yearSpan %  xInterval !=0 || (yearSpan/xInterval) > 13.0){
          xInterval +=1;
          //if it gets to a 25 year interval, assume the number is prime and...
          if(xInterval > 24){
             println("yearSpan error: Program currently can't deal with prime number spans or spans that require intervals greater than 24 years."); 
             break;
          }
        } 
      }
      
      //set yearsPerPx and pxPerYear
      float yearsPerPx = float(yearSpan) / float(w);
      float pxPerYear = float(w) / float(yearSpan);
      
      //loop through years and write lines every year, xTic and year text every xInterval
      for(int i = yearStart; i<yearEnd; i++){
        String var1_temp1 = var1_pre + str(i);
        String var1_temp2 = var1_pre + str(i+1);
        String var2_temp1 = var2_pre + str(i);
        String var2_temp2 = var2_pre + str(i+1);
        
        Float var1_tempData1 = data.getFloat(cr, var1_temp1);
        Float var1_tempData2 = data.getFloat(cr, var1_temp2);
        Float var2_tempData1 = data.getFloat(cr, var2_temp1);
        Float var2_tempData2 = data.getFloat(cr, var2_temp2);
        
        float x1 = xPos+(i-yearStart)*pxPerYear;
        float x2 = xPos+((i-yearStart+1)*pxPerYear);
        
        //vertical blue line at 2004
        if(i==2004){
         strokeWeight(1);
         stroke(51,204,255); 
         line(x1, yPos, x1, yBaseLoc);
        }
        
        //write y scale text, y lines (this has to be here in order to be over the blue line)
        //do it only once per graph
        if(!yLinesDrawn){
          for(int j=0; j<((yRange+yInterval)/yInterval); j++){
            float yCurLoc = yBaseLoc - ((yInterval*(j))*pxPerY);
            float yVal = yMin + (j)*yInterval;
            textFont(graphNumbers);
            textAlign(RIGHT, CENTER);
            fill(51,51,51);
            text(nf(yVal, 0, 0), xPos-3, yCurLoc);
            strokeWeight(1);
            stroke(153,153,153);
            line(xPos, yCurLoc, xPos+w, yCurLoc);
            yLinesDrawn = true;
          }
        }
        
        //tic marks and text
        if((i-yearStart) % xInterval ==0){
          textFont(graphNumbers);
          textAlign(CENTER, TOP);
          stroke(153,153,153);
          strokeWeight(1);
          line(x1, yBaseLoc, x1, yBaseLoc+2);
          //format years for x legend
          int yr = i;
          if(yr>1999) yr = yr - 2000;
          else yr = yr - 1900;
          String yearStr = "'" + nf(yr, 2, 0);
          
          text(yearStr, x1, yBaseLoc + 4);
          //for final year, already checked modulo above
          if(i==yearEnd-xInterval){
            line(x1+(xInterval*pxPerYear), yBaseLoc, x1+(xInterval*pxPerYear), yBaseLoc+2);
            //format years for x legend
            int yrFinal = i+xInterval;
            if(yrFinal>1999) yrFinal = yrFinal - 2000;
            else yrFinal = yrFinal - 1900;
            String yearStrFinal = "'" + nf(yrFinal, 2, 0);
            
            text(yearStrFinal, x1+(xInterval*pxPerYear), yBaseLoc + 4);
          }
        }
        
        //lines on top
        strokeWeight(2);
        //var 2 is the bottom line and blue
        stroke(0,102,153);
        line(x1, yBaseLoc-(var2_tempData1*pxPerY), x2, yBaseLoc-(var2_tempData2*pxPerY));
        
        //var 1 is the top line and orange
        stroke(255,153,51);
        line(x1, yBaseLoc-(var1_tempData1*pxPerY), x2, yBaseLoc-(var1_tempData2*pxPerY));
      }
    
  }
  //class methods go here
}
void numbers2015(){
  int county = data.getInt(cr, "county_listedstock_2015");
  int state = data.getInt(cr, "listedstock_2015");
  int national = data.getInt(cr, "national_listings_2015");
  
  textFont(numbers2015);
  textAlign(CENTER, BOTTOM);
  stroke(0);
  fill(0);
  text(county, 230, 189);
  text(state, 450, 189);
  text(national, 670, 189);
  
}
void countyNumbers2015(){
  int endangered = data.getInt(cr, "endangeredstock15");
  int threatened = data.getInt(cr, "threatenedstock15");
  int newListing = data.getInt(cr, "newspecies04_15");
  int delisting = data.getInt(cr, "delisted04_15");
  int pop14 = data.getInt(cr, "Pop_LT_Population");
  
  textFont(countyNumbers2015);
  stroke(0);
  fill(0);
  textAlign(RIGHT, BOTTOM);
  text(endangered, 286, 403);
  text(threatened, 286, 422);
  text(newListing, 286, 452);
  text(delisting, 286, 482);
  
  textAlign(CENTER, BOTTOM);
  text(pop14, 79, 424);
}

