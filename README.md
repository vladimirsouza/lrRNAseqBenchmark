
<!-- README.md is generated from README.Rmd. Please edit that file -->

(This is a draft)

# lrRNAseqBenchmark

<!-- badges: start -->
<!-- badges: end -->

Use ground-truth VCF files generated from short-read data to compare and
validate VCF files generated from different variant callers on Iso-Seq
data.

## Installation

To install it use
`devtools::install_github("vladimirsouza/lrRNAseqBenchmark@main")`.

## An example on how to construct a master table

We construct a master table that contains information about the variants
called by the methods to be validated and the variants in the
ground-truth. From this master table, we can generate plots and analyze
and compare the VCF files used to construct the table.

### Introduction

Generate a new master table to compare and validate the variant calls
from Iso-Seq data when using DeepVariant alone and SplitNCigarReads +
DeepVariant. The ground-truth was generated by GATK pipeline on
short-read DNA data.

### Input variables

``` r
### methods to validate
# name of the methods to validate
METHOD_NAMES <- c("dv", "dv_s")
# name of the dataset used with the methods to validate
METHOD_DATASET_NAME <- "isoSeq"
# VCF files
METHOD1_VCF_FILE <- "/home/vbarbo/project_2021/datasets/gloria_data/analysis/dv_calls/noSplitBam/deepvariant_calls_pass.vcf.gz"
METHOD2_VCF_FILE <- "/home/vbarbo/project_2021/datasets/gloria_data/analysis/dv_calls/deepvariant_calls_pass.vcf.gz"
# BAM of the data
METHOD_BAM_FILE <- "/home/vbarbo/project_2021/datasets/gloria_data/analysis/dv_calls/aln_rg_dedupped.bam"


### ground-truth
# name
TRUTH_NAME <- "tr_dna_merged"
# name of the dataset used to generate the ground-truth
TRUTH_DATASET_NAME <- "shortRead"
# VCF file
TRUTH_VCF_FILE <- "/home/vbarbo/project_2021/datasets/gloria_data/analysis/truth_merged_bams/merged.recal_exons_pass.vcf.gz"
# BAM of the data
TRUTH_BAM_FILE <- "/home/vbarbo/project_2021/datasets/gloria_data/analysis/truth_merged_bams/merged.bam"


### variables
MAX_DIST_FROM_SPLICE_SITE <- 20
THREADS <- 40
```

### libraries

``` r
library(lrRNAseqBenchmark)
library(GenomicAlignments)
library(dplyr)
```

### Create the master table

#### Initiate the master table

Get variant positions and which method could call them.

``` r
dat <- initiate_master_table(
  METHOD1_VCF_FILE, 
  METHOD2_VCF_FILE, 
  TRUTH_VCF_FILE,
  method_names=c(METHOD_NAMES, TRUTH_NAME)
)
```

#### get splice site positions from the BAM file

NOTE: This function may take a long time to run.

``` r
### don't run this
splice_sites <- get_splice_sites_info(input_bam, THREADS)
```

#### Add columns about splice sites

``` r
dat <- add_splice_site_info_to_master_table(
  dat, splice_sites,
  MAX_DIST_FROM_SPLICE_SITE
)
```

#### Add the read coverage (from the BAM file) of each variant

First, we need to load the BAM file and get the coverage with
`IRanges::coverage`.

``` r
method_bam <- readGAlignments(METHOD_BAM_FILE)
method_coverage <- coverage(method_bam)

truth_bam <- readGAlignments(TRUTH_BAM_FILE)
truth_coverage <- coverage(truth_bam)
```

Add read coverage of each dataset.

``` r
dat <- add_read_coverage_from_bam_to_master_table(
  method_coverage,
  truth_coverage,
  input_table=dat,
  dataset_names=c(METHOD_DATASET_NAME, TRUTH_DATASET_NAME)
)
```

#### Add the number of N-cigar reads per site

``` r
dat <- add_number_of_n_cigar_reads_to_master_table(
  dat, 
  method_bam, 
  METHOD_DATASET_NAME
)
```

#### Add column to comprare two methods

Compare `dv` and `dv_s`. Do they call the same varaints?

``` r
dat <- add_two_method_comparison_to_master_table(
  dat, 
  METHOD_NAMES[1], 
  METHOD_NAMES[2]
)
```

#### Add column to classify the method calls (compare to the ground-truth)

Classify `dv` calls.

``` r
dat <- add_method_vs_truth_comparison_to_master_table(
  dat, 
  METHOD_NAMES[1], 
  TRUTH_NAME
)
```

Classify `dv_s` calls.

``` r
dat <- add_method_vs_truth_comparison_to_master_table(
  dat, 
  METHOD_NAMES[2], 
  TRUTH_NAME
)
```

#### Add columns to inform whether the variant is a indel or not

For the ground-truth

``` r
dat <- add_the_ground_truth_indel_information_to_master_table(
  dat,
  TRUTH_VCF_FILE,
  TRUTH_NAME
)
#> Scanning file to determine attributes.
#> File attributes:
#>   meta lines: 75
#>   header_line: 76
#>   variant count: 928412
#>   column count: 10
#> Meta line 75 read in.
#> All meta lines processed.
#> gt matrix initialized.
#> Character matrix gt created.
#>   Character matrix gt rows: 928412
#>   Character matrix gt cols: 10
#>   skip: 0
#>   nrows: 928412
#>   row_num: 0
#> Processed variant 1000Processed variant 2000Processed variant 3000Processed variant 4000Processed variant 5000Processed variant 6000Processed variant 7000Processed variant 8000Processed variant 9000Processed variant 10000Processed variant 11000Processed variant 12000Processed variant 13000Processed variant 14000Processed variant 15000Processed variant 16000Processed variant 17000Processed variant 18000Processed variant 19000Processed variant 20000Processed variant 21000Processed variant 22000Processed variant 23000Processed variant 24000Processed variant 25000Processed variant 26000Processed variant 27000Processed variant 28000Processed variant 29000Processed variant 30000Processed variant 31000Processed variant 32000Processed variant 33000Processed variant 34000Processed variant 35000Processed variant 36000Processed variant 37000Processed variant 38000Processed variant 39000Processed variant 40000Processed variant 41000Processed variant 42000Processed variant 43000Processed variant 44000Processed variant 45000Processed variant 46000Processed variant 47000Processed variant 48000Processed variant 49000Processed variant 50000Processed variant 51000Processed variant 52000Processed variant 53000Processed variant 54000Processed variant 55000Processed variant 56000Processed variant 57000Processed variant 58000Processed variant 59000Processed variant 60000Processed variant 61000Processed variant 62000Processed variant 63000Processed variant 64000Processed variant 65000Processed variant 66000Processed variant 67000Processed variant 68000Processed variant 69000Processed variant 70000Processed variant 71000Processed variant 72000Processed variant 73000Processed variant 74000Processed variant 75000Processed variant 76000Processed variant 77000Processed variant 78000Processed variant 79000Processed variant 80000Processed variant 81000Processed variant 82000Processed variant 83000Processed variant 84000Processed variant 85000Processed variant 86000Processed variant 87000Processed variant 88000Processed variant 89000Processed variant 90000Processed variant 91000Processed variant 92000Processed variant 93000Processed variant 94000Processed variant 95000Processed variant 96000Processed variant 97000Processed variant 98000Processed variant 99000Processed variant 100000Processed variant 101000Processed variant 102000Processed variant 103000Processed variant 104000Processed variant 105000Processed variant 106000Processed variant 107000Processed variant 108000Processed variant 109000Processed variant 110000Processed variant 111000Processed variant 112000Processed variant 113000Processed variant 114000Processed variant 115000Processed variant 116000Processed variant 117000Processed variant 118000Processed variant 119000Processed variant 120000Processed variant 121000Processed variant 122000Processed variant 123000Processed variant 124000Processed variant 125000Processed variant 126000Processed variant 127000Processed variant 128000Processed variant 129000Processed variant 130000Processed variant 131000Processed variant 132000Processed variant 133000Processed variant 134000Processed variant 135000Processed variant 136000Processed variant 137000Processed variant 138000Processed variant 139000Processed variant 140000Processed variant 141000Processed variant 142000Processed variant 143000Processed variant 144000Processed variant 145000Processed variant 146000Processed variant 147000Processed variant 148000Processed variant 149000Processed variant 150000Processed variant 151000Processed variant 152000Processed variant 153000Processed variant 154000Processed variant 155000Processed variant 156000Processed variant 157000Processed variant 158000Processed variant 159000Processed variant 160000Processed variant 161000Processed variant 162000Processed variant 163000Processed variant 164000Processed variant 165000Processed variant 166000Processed variant 167000Processed variant 168000Processed variant 169000Processed variant 170000Processed variant 171000Processed variant 172000Processed variant 173000Processed variant 174000Processed variant 175000Processed variant 176000Processed variant 177000Processed variant 178000Processed variant 179000Processed variant 180000Processed variant 181000Processed variant 182000Processed variant 183000Processed variant 184000Processed variant 185000Processed variant 186000Processed variant 187000Processed variant 188000Processed variant 189000Processed variant 190000Processed variant 191000Processed variant 192000Processed variant 193000Processed variant 194000Processed variant 195000Processed variant 196000Processed variant 197000Processed variant 198000Processed variant 199000Processed variant 200000Processed variant 201000Processed variant 202000Processed variant 203000Processed variant 204000Processed variant 205000Processed variant 206000Processed variant 207000Processed variant 208000Processed variant 209000Processed variant 210000Processed variant 211000Processed variant 212000Processed variant 213000Processed variant 214000Processed variant 215000Processed variant 216000Processed variant 217000Processed variant 218000Processed variant 219000Processed variant 220000Processed variant 221000Processed variant 222000Processed variant 223000Processed variant 224000Processed variant 225000Processed variant 226000Processed variant 227000Processed variant 228000Processed variant 229000Processed variant 230000Processed variant 231000Processed variant 232000Processed variant 233000Processed variant 234000Processed variant 235000Processed variant 236000Processed variant 237000Processed variant 238000Processed variant 239000Processed variant 240000Processed variant 241000Processed variant 242000Processed variant 243000Processed variant 244000Processed variant 245000Processed variant 246000Processed variant 247000Processed variant 248000Processed variant 249000Processed variant 250000Processed variant 251000Processed variant 252000Processed variant 253000Processed variant 254000Processed variant 255000Processed variant 256000Processed variant 257000Processed variant 258000Processed variant 259000Processed variant 260000Processed variant 261000Processed variant 262000Processed variant 263000Processed variant 264000Processed variant 265000Processed variant 266000Processed variant 267000Processed variant 268000Processed variant 269000Processed variant 270000Processed variant 271000Processed variant 272000Processed variant 273000Processed variant 274000Processed variant 275000Processed variant 276000Processed variant 277000Processed variant 278000Processed variant 279000Processed variant 280000Processed variant 281000Processed variant 282000Processed variant 283000Processed variant 284000Processed variant 285000Processed variant 286000Processed variant 287000Processed variant 288000Processed variant 289000Processed variant 290000Processed variant 291000Processed variant 292000Processed variant 293000Processed variant 294000Processed variant 295000Processed variant 296000Processed variant 297000Processed variant 298000Processed variant 299000Processed variant 300000Processed variant 301000Processed variant 302000Processed variant 303000Processed variant 304000Processed variant 305000Processed variant 306000Processed variant 307000Processed variant 308000Processed variant 309000Processed variant 310000Processed variant 311000Processed variant 312000Processed variant 313000Processed variant 314000Processed variant 315000Processed variant 316000Processed variant 317000Processed variant 318000Processed variant 319000Processed variant 320000Processed variant 321000Processed variant 322000Processed variant 323000Processed variant 324000Processed variant 325000Processed variant 326000Processed variant 327000Processed variant 328000Processed variant 329000Processed variant 330000Processed variant 331000Processed variant 332000Processed variant 333000Processed variant 334000Processed variant 335000Processed variant 336000Processed variant 337000Processed variant 338000Processed variant 339000Processed variant 340000Processed variant 341000Processed variant 342000Processed variant 343000Processed variant 344000Processed variant 345000Processed variant 346000Processed variant 347000Processed variant 348000Processed variant 349000Processed variant 350000Processed variant 351000Processed variant 352000Processed variant 353000Processed variant 354000Processed variant 355000Processed variant 356000Processed variant 357000Processed variant 358000Processed variant 359000Processed variant 360000Processed variant 361000Processed variant 362000Processed variant 363000Processed variant 364000Processed variant 365000Processed variant 366000Processed variant 367000Processed variant 368000Processed variant 369000Processed variant 370000Processed variant 371000Processed variant 372000Processed variant 373000Processed variant 374000Processed variant 375000Processed variant 376000Processed variant 377000Processed variant 378000Processed variant 379000Processed variant 380000Processed variant 381000Processed variant 382000Processed variant 383000Processed variant 384000Processed variant 385000Processed variant 386000Processed variant 387000Processed variant 388000Processed variant 389000Processed variant 390000Processed variant 391000Processed variant 392000Processed variant 393000Processed variant 394000Processed variant 395000Processed variant 396000Processed variant 397000Processed variant 398000Processed variant 399000Processed variant 400000Processed variant 401000Processed variant 402000Processed variant 403000Processed variant 404000Processed variant 405000Processed variant 406000Processed variant 407000Processed variant 408000Processed variant 409000Processed variant 410000Processed variant 411000Processed variant 412000Processed variant 413000Processed variant 414000Processed variant 415000Processed variant 416000Processed variant 417000Processed variant 418000Processed variant 419000Processed variant 420000Processed variant 421000Processed variant 422000Processed variant 423000Processed variant 424000Processed variant 425000Processed variant 426000Processed variant 427000Processed variant 428000Processed variant 429000Processed variant 430000Processed variant 431000Processed variant 432000Processed variant 433000Processed variant 434000Processed variant 435000Processed variant 436000Processed variant 437000Processed variant 438000Processed variant 439000Processed variant 440000Processed variant 441000Processed variant 442000Processed variant 443000Processed variant 444000Processed variant 445000Processed variant 446000Processed variant 447000Processed variant 448000Processed variant 449000Processed variant 450000Processed variant 451000Processed variant 452000Processed variant 453000Processed variant 454000Processed variant 455000Processed variant 456000Processed variant 457000Processed variant 458000Processed variant 459000Processed variant 460000Processed variant 461000Processed variant 462000Processed variant 463000Processed variant 464000Processed variant 465000Processed variant 466000Processed variant 467000Processed variant 468000Processed variant 469000Processed variant 470000Processed variant 471000Processed variant 472000Processed variant 473000Processed variant 474000Processed variant 475000Processed variant 476000Processed variant 477000Processed variant 478000Processed variant 479000Processed variant 480000Processed variant 481000Processed variant 482000Processed variant 483000Processed variant 484000Processed variant 485000Processed variant 486000Processed variant 487000Processed variant 488000Processed variant 489000Processed variant 490000Processed variant 491000Processed variant 492000Processed variant 493000Processed variant 494000Processed variant 495000Processed variant 496000Processed variant 497000Processed variant 498000Processed variant 499000Processed variant 500000Processed variant 501000Processed variant 502000Processed variant 503000Processed variant 504000Processed variant 505000Processed variant 506000Processed variant 507000Processed variant 508000Processed variant 509000Processed variant 510000Processed variant 511000Processed variant 512000Processed variant 513000Processed variant 514000Processed variant 515000Processed variant 516000Processed variant 517000Processed variant 518000Processed variant 519000Processed variant 520000Processed variant 521000Processed variant 522000Processed variant 523000Processed variant 524000Processed variant 525000Processed variant 526000Processed variant 527000Processed variant 528000Processed variant 529000Processed variant 530000Processed variant 531000Processed variant 532000Processed variant 533000Processed variant 534000Processed variant 535000Processed variant 536000Processed variant 537000Processed variant 538000Processed variant 539000Processed variant 540000Processed variant 541000Processed variant 542000Processed variant 543000Processed variant 544000Processed variant 545000Processed variant 546000Processed variant 547000Processed variant 548000Processed variant 549000Processed variant 550000Processed variant 551000Processed variant 552000Processed variant 553000Processed variant 554000Processed variant 555000Processed variant 556000Processed variant 557000Processed variant 558000Processed variant 559000Processed variant 560000Processed variant 561000Processed variant 562000Processed variant 563000Processed variant 564000Processed variant 565000Processed variant 566000Processed variant 567000Processed variant 568000Processed variant 569000Processed variant 570000Processed variant 571000Processed variant 572000Processed variant 573000Processed variant 574000Processed variant 575000Processed variant 576000Processed variant 577000Processed variant 578000Processed variant 579000Processed variant 580000Processed variant 581000Processed variant 582000Processed variant 583000Processed variant 584000Processed variant 585000Processed variant 586000Processed variant 587000Processed variant 588000Processed variant 589000Processed variant 590000Processed variant 591000Processed variant 592000Processed variant 593000Processed variant 594000Processed variant 595000Processed variant 596000Processed variant 597000Processed variant 598000Processed variant 599000Processed variant 600000Processed variant 601000Processed variant 602000Processed variant 603000Processed variant 604000Processed variant 605000Processed variant 606000Processed variant 607000Processed variant 608000Processed variant 609000Processed variant 610000Processed variant 611000Processed variant 612000Processed variant 613000Processed variant 614000Processed variant 615000Processed variant 616000Processed variant 617000Processed variant 618000Processed variant 619000Processed variant 620000Processed variant 621000Processed variant 622000Processed variant 623000Processed variant 624000Processed variant 625000Processed variant 626000Processed variant 627000Processed variant 628000Processed variant 629000Processed variant 630000Processed variant 631000Processed variant 632000Processed variant 633000Processed variant 634000Processed variant 635000Processed variant 636000Processed variant 637000Processed variant 638000Processed variant 639000Processed variant 640000Processed variant 641000Processed variant 642000Processed variant 643000Processed variant 644000Processed variant 645000Processed variant 646000Processed variant 647000Processed variant 648000Processed variant 649000Processed variant 650000Processed variant 651000Processed variant 652000Processed variant 653000Processed variant 654000Processed variant 655000Processed variant 656000Processed variant 657000Processed variant 658000Processed variant 659000Processed variant 660000Processed variant 661000Processed variant 662000Processed variant 663000Processed variant 664000Processed variant 665000Processed variant 666000Processed variant 667000Processed variant 668000Processed variant 669000Processed variant 670000Processed variant 671000Processed variant 672000Processed variant 673000Processed variant 674000Processed variant 675000Processed variant 676000Processed variant 677000Processed variant 678000Processed variant 679000Processed variant 680000Processed variant 681000Processed variant 682000Processed variant 683000Processed variant 684000Processed variant 685000Processed variant 686000Processed variant 687000Processed variant 688000Processed variant 689000Processed variant 690000Processed variant 691000Processed variant 692000Processed variant 693000Processed variant 694000Processed variant 695000Processed variant 696000Processed variant 697000Processed variant 698000Processed variant 699000Processed variant 700000Processed variant 701000Processed variant 702000Processed variant 703000Processed variant 704000Processed variant 705000Processed variant 706000Processed variant 707000Processed variant 708000Processed variant 709000Processed variant 710000Processed variant 711000Processed variant 712000Processed variant 713000Processed variant 714000Processed variant 715000Processed variant 716000Processed variant 717000Processed variant 718000Processed variant 719000Processed variant 720000Processed variant 721000Processed variant 722000Processed variant 723000Processed variant 724000Processed variant 725000Processed variant 726000Processed variant 727000Processed variant 728000Processed variant 729000Processed variant 730000Processed variant 731000Processed variant 732000Processed variant 733000Processed variant 734000Processed variant 735000Processed variant 736000Processed variant 737000Processed variant 738000Processed variant 739000Processed variant 740000Processed variant 741000Processed variant 742000Processed variant 743000Processed variant 744000Processed variant 745000Processed variant 746000Processed variant 747000Processed variant 748000Processed variant 749000Processed variant 750000Processed variant 751000Processed variant 752000Processed variant 753000Processed variant 754000Processed variant 755000Processed variant 756000Processed variant 757000Processed variant 758000Processed variant 759000Processed variant 760000Processed variant 761000Processed variant 762000Processed variant 763000Processed variant 764000Processed variant 765000Processed variant 766000Processed variant 767000Processed variant 768000Processed variant 769000Processed variant 770000Processed variant 771000Processed variant 772000Processed variant 773000Processed variant 774000Processed variant 775000Processed variant 776000Processed variant 777000Processed variant 778000Processed variant 779000Processed variant 780000Processed variant 781000Processed variant 782000Processed variant 783000Processed variant 784000Processed variant 785000Processed variant 786000Processed variant 787000Processed variant 788000Processed variant 789000Processed variant 790000Processed variant 791000Processed variant 792000Processed variant 793000Processed variant 794000Processed variant 795000Processed variant 796000Processed variant 797000Processed variant 798000Processed variant 799000Processed variant 800000Processed variant 801000Processed variant 802000Processed variant 803000Processed variant 804000Processed variant 805000Processed variant 806000Processed variant 807000Processed variant 808000Processed variant 809000Processed variant 810000Processed variant 811000Processed variant 812000Processed variant 813000Processed variant 814000Processed variant 815000Processed variant 816000Processed variant 817000Processed variant 818000Processed variant 819000Processed variant 820000Processed variant 821000Processed variant 822000Processed variant 823000Processed variant 824000Processed variant 825000Processed variant 826000Processed variant 827000Processed variant 828000Processed variant 829000Processed variant 830000Processed variant 831000Processed variant 832000Processed variant 833000Processed variant 834000Processed variant 835000Processed variant 836000Processed variant 837000Processed variant 838000Processed variant 839000Processed variant 840000Processed variant 841000Processed variant 842000Processed variant 843000Processed variant 844000Processed variant 845000Processed variant 846000Processed variant 847000Processed variant 848000Processed variant 849000Processed variant 850000Processed variant 851000Processed variant 852000Processed variant 853000Processed variant 854000Processed variant 855000Processed variant 856000Processed variant 857000Processed variant 858000Processed variant 859000Processed variant 860000Processed variant 861000Processed variant 862000Processed variant 863000Processed variant 864000Processed variant 865000Processed variant 866000Processed variant 867000Processed variant 868000Processed variant 869000Processed variant 870000Processed variant 871000Processed variant 872000Processed variant 873000Processed variant 874000Processed variant 875000Processed variant 876000Processed variant 877000Processed variant 878000Processed variant 879000Processed variant 880000Processed variant 881000Processed variant 882000Processed variant 883000Processed variant 884000Processed variant 885000Processed variant 886000Processed variant 887000Processed variant 888000Processed variant 889000Processed variant 890000Processed variant 891000Processed variant 892000Processed variant 893000Processed variant 894000Processed variant 895000Processed variant 896000Processed variant 897000Processed variant 898000Processed variant 899000Processed variant 900000Processed variant 901000Processed variant 902000Processed variant 903000Processed variant 904000Processed variant 905000Processed variant 906000Processed variant 907000Processed variant 908000Processed variant 909000Processed variant 910000Processed variant 911000Processed variant 912000Processed variant 913000Processed variant 914000Processed variant 915000Processed variant 916000Processed variant 917000Processed variant 918000Processed variant 919000Processed variant 920000Processed variant 921000Processed variant 922000Processed variant 923000Processed variant 924000Processed variant 925000Processed variant 926000Processed variant 927000Processed variant 928000Processed variant: 928412
#> All variants processed
#> Warning in check_keys(vcf): The following INFO key occurred more than once: ##GATKCommandLine=<ID=ApplyVQSR
```

For the methods

``` r
### method 1
dat <- add_a_method_indel_information_to_master_table(
  dat,
  METHOD1_VCF_FILE,
  METHOD_NAMES[1],
  TRUTH_NAME
)
#> Scanning file to determine attributes.
#> File attributes:
#>   meta lines: 39
#>   header_line: 40
#>   variant count: 139611
#>   column count: 10
#> Meta line 39 read in.
#> All meta lines processed.
#> gt matrix initialized.
#> Character matrix gt created.
#>   Character matrix gt rows: 139611
#>   Character matrix gt cols: 10
#>   skip: 0
#>   nrows: 139611
#>   row_num: 0
#> Processed variant 1000Processed variant 2000Processed variant 3000Processed variant 4000Processed variant 5000Processed variant 6000Processed variant 7000Processed variant 8000Processed variant 9000Processed variant 10000Processed variant 11000Processed variant 12000Processed variant 13000Processed variant 14000Processed variant 15000Processed variant 16000Processed variant 17000Processed variant 18000Processed variant 19000Processed variant 20000Processed variant 21000Processed variant 22000Processed variant 23000Processed variant 24000Processed variant 25000Processed variant 26000Processed variant 27000Processed variant 28000Processed variant 29000Processed variant 30000Processed variant 31000Processed variant 32000Processed variant 33000Processed variant 34000Processed variant 35000Processed variant 36000Processed variant 37000Processed variant 38000Processed variant 39000Processed variant 40000Processed variant 41000Processed variant 42000Processed variant 43000Processed variant 44000Processed variant 45000Processed variant 46000Processed variant 47000Processed variant 48000Processed variant 49000Processed variant 50000Processed variant 51000Processed variant 52000Processed variant 53000Processed variant 54000Processed variant 55000Processed variant 56000Processed variant 57000Processed variant 58000Processed variant 59000Processed variant 60000Processed variant 61000Processed variant 62000Processed variant 63000Processed variant 64000Processed variant 65000Processed variant 66000Processed variant 67000Processed variant 68000Processed variant 69000Processed variant 70000Processed variant 71000Processed variant 72000Processed variant 73000Processed variant 74000Processed variant 75000Processed variant 76000Processed variant 77000Processed variant 78000Processed variant 79000Processed variant 80000Processed variant 81000Processed variant 82000Processed variant 83000Processed variant 84000Processed variant 85000Processed variant 86000Processed variant 87000Processed variant 88000Processed variant 89000Processed variant 90000Processed variant 91000Processed variant 92000Processed variant 93000Processed variant 94000Processed variant 95000Processed variant 96000Processed variant 97000Processed variant 98000Processed variant 99000Processed variant 100000Processed variant 101000Processed variant 102000Processed variant 103000Processed variant 104000Processed variant 105000Processed variant 106000Processed variant 107000Processed variant 108000Processed variant 109000Processed variant 110000Processed variant 111000Processed variant 112000Processed variant 113000Processed variant 114000Processed variant 115000Processed variant 116000Processed variant 117000Processed variant 118000Processed variant 119000Processed variant 120000Processed variant 121000Processed variant 122000Processed variant 123000Processed variant 124000Processed variant 125000Processed variant 126000Processed variant 127000Processed variant 128000Processed variant 129000Processed variant 130000Processed variant 131000Processed variant 132000Processed variant 133000Processed variant 134000Processed variant 135000Processed variant 136000Processed variant 137000Processed variant 138000Processed variant 139000Processed variant: 139611
#> All variants processed

### method 2
dat <- add_a_method_indel_information_to_master_table(
  dat,
  METHOD2_VCF_FILE,
  METHOD_NAMES[2],
  TRUTH_NAME
)
#> Scanning file to determine attributes.
#> File attributes:
#>   meta lines: 39
#>   header_line: 40
#>   variant count: 153520
#>   column count: 10
#> Meta line 39 read in.
#> All meta lines processed.
#> gt matrix initialized.
#> Character matrix gt created.
#>   Character matrix gt rows: 153520
#>   Character matrix gt cols: 10
#>   skip: 0
#>   nrows: 153520
#>   row_num: 0
#> Processed variant 1000Processed variant 2000Processed variant 3000Processed variant 4000Processed variant 5000Processed variant 6000Processed variant 7000Processed variant 8000Processed variant 9000Processed variant 10000Processed variant 11000Processed variant 12000Processed variant 13000Processed variant 14000Processed variant 15000Processed variant 16000Processed variant 17000Processed variant 18000Processed variant 19000Processed variant 20000Processed variant 21000Processed variant 22000Processed variant 23000Processed variant 24000Processed variant 25000Processed variant 26000Processed variant 27000Processed variant 28000Processed variant 29000Processed variant 30000Processed variant 31000Processed variant 32000Processed variant 33000Processed variant 34000Processed variant 35000Processed variant 36000Processed variant 37000Processed variant 38000Processed variant 39000Processed variant 40000Processed variant 41000Processed variant 42000Processed variant 43000Processed variant 44000Processed variant 45000Processed variant 46000Processed variant 47000Processed variant 48000Processed variant 49000Processed variant 50000Processed variant 51000Processed variant 52000Processed variant 53000Processed variant 54000Processed variant 55000Processed variant 56000Processed variant 57000Processed variant 58000Processed variant 59000Processed variant 60000Processed variant 61000Processed variant 62000Processed variant 63000Processed variant 64000Processed variant 65000Processed variant 66000Processed variant 67000Processed variant 68000Processed variant 69000Processed variant 70000Processed variant 71000Processed variant 72000Processed variant 73000Processed variant 74000Processed variant 75000Processed variant 76000Processed variant 77000Processed variant 78000Processed variant 79000Processed variant 80000Processed variant 81000Processed variant 82000Processed variant 83000Processed variant 84000Processed variant 85000Processed variant 86000Processed variant 87000Processed variant 88000Processed variant 89000Processed variant 90000Processed variant 91000Processed variant 92000Processed variant 93000Processed variant 94000Processed variant 95000Processed variant 96000Processed variant 97000Processed variant 98000Processed variant 99000Processed variant 100000Processed variant 101000Processed variant 102000Processed variant 103000Processed variant 104000Processed variant 105000Processed variant 106000Processed variant 107000Processed variant 108000Processed variant 109000Processed variant 110000Processed variant 111000Processed variant 112000Processed variant 113000Processed variant 114000Processed variant 115000Processed variant 116000Processed variant 117000Processed variant 118000Processed variant 119000Processed variant 120000Processed variant 121000Processed variant 122000Processed variant 123000Processed variant 124000Processed variant 125000Processed variant 126000Processed variant 127000Processed variant 128000Processed variant 129000Processed variant 130000Processed variant 131000Processed variant 132000Processed variant 133000Processed variant 134000Processed variant 135000Processed variant 136000Processed variant 137000Processed variant 138000Processed variant 139000Processed variant 140000Processed variant 141000Processed variant 142000Processed variant 143000Processed variant 144000Processed variant 145000Processed variant 146000Processed variant 147000Processed variant 148000Processed variant 149000Processed variant 150000Processed variant 151000Processed variant 152000Processed variant 153000Processed variant: 153520
#> All variants processed
```

### Take a look at the master table

``` r
head(dat)
#>   chrm   pos in_dv in_dv_s in_tr_dna_merged dp_dv dp_dv_s dp_tr_dna_merged is_near_ss ss_dist
#> 1 chr1 15274     1       1                0     5       2               NA          0      NA
#> 2 chr1 15817     1       0                0    19      NA               NA          0      NA
#> 3 chr1 15820     1       0                0    19      NA               NA          0      NA
#> 4 chr1 15903     1       0                0    19      NA               NA          0      NA
#> 5 chr1 16933     1       0                0    20      NA               NA          0      NA
#> 6 chr1 18849     1       0                0     2      NA               NA          0      NA
#>   is_acceptor_site ss_num is_single_ss ss_shortest_dist ss_highest_num is_acceptor_site_mode
#> 1               NA     NA           -1             2000              0                  <NA>
#> 2               NA     NA           -1             2000              0                  <NA>
#> 3               NA     NA           -1             2000              0                  <NA>
#> 4               NA     NA           -1             2000              0                  <NA>
#> 5               NA     NA           -1             2000              0                  <NA>
#> 6               NA     NA           -1             2000              0                  <NA>
#>   isoSeq_coverage shortRead_coverage isoSeq_ncr_num compare_dv_dvS dv_classification
#> 1              16                  0             69           both                FP
#> 2              83                  3              0             dv                FP
#> 3              83                  3              0             dv                FP
#> 4              83                  0              0             dv                FP
#> 5              89                  5              0             dv                FP
#> 6               4                  0             81             dv                FP
#>   dv_s_classification is_indel_tr_dna_merged is_indel_dv is_indel_dv_s
#> 1                  FP                     NA           0             0
#> 2                  TN                     NA           0            NA
#> 3                  TN                     NA           0            NA
#> 4                  TN                     NA           1            NA
#> 5                  TN                     NA           0            NA
#> 6                  TN                     NA           0            NA
```

### Subset and calculate the precision, sensitivity and F1-score of the methods

Take only variants in well-coverage regions in both Iso-Seq and
short-read data.

``` r
well_coverage_dat <- filter(dat, 
                            isoSeq_coverage>=10 & shortRead_coverage>=40 &
                              shortRead_coverage<=70)
```

Calculate accuracy measures for dv.

``` r
calc_accuracy_measures(well_coverage_dat, METHOD_NAMES[1], TRUTH_NAME)
#>   precision sensitivity     f1Score 
#>   0.8005915   0.6610849   0.7241808
```

Calculate accuracy measures for dv\_s.

``` r
calc_accuracy_measures(well_coverage_dat, METHOD_NAMES[2], TRUTH_NAME)
#>   precision sensitivity     f1Score 
#>   0.7836834   0.6442526   0.7071606
```
