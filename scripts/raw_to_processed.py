"""
raw_to_processed.py
AWS Glue ETL job to transform raw data into processed format

This script:
1. Reads raw data from the raw S3 bucket
2. Performs data quality checks and cleansing
3. Applies transformations (filtering, deduplication, type casting)
4. Writes processed data to the processed S3 bucket in Parquet format
"""

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, to_timestamp, when, trim, upper
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get job parameters
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'SOURCE_BUCKET',
    'TARGET_BUCKET',
    'DATABASE_NAME'
])

# Initialize Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info(f"Starting job: {args['JOB_NAME']}")
logger.info(f"Source bucket: {args['SOURCE_BUCKET']}")
logger.info(f"Target bucket: {args['TARGET_BUCKET']}")

try:
    # Read raw data from S3
    # Adjust the path pattern based on your data structure
    source_path = f"s3://{args['SOURCE_BUCKET']}/data/"
    logger.info(f"Reading data from: {source_path}")
    
    # Read data as DynamicFrame
    raw_dynamic_frame = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={
            "paths": [source_path],
            "recurse": True
        },
        format="json",  # Change to "csv", "parquet", etc. based on your raw data format
        transformation_ctx="raw_dynamic_frame"
    )
    
    # Convert to Spark DataFrame for easier transformations
    df = raw_dynamic_frame.toDF()
    
    logger.info(f"Read {df.count()} records from raw data")
    logger.info(f"Schema: {df.printSchema()}")
    
    # ====================================================================
    # Data Quality & Cleansing
    # ====================================================================
    
    # Remove duplicate records
    df = df.dropDuplicates()
    logger.info(f"After deduplication: {df.count()} records")
    
    # Remove records with null in critical columns (adjust column names as needed)
    # df = df.filter(col("id").isNotNull())
    
    # Trim whitespace from string columns
    string_columns = [field.name for field in df.schema.fields if str(field.dataType) == "StringType"]
    for col_name in string_columns:
        df = df.withColumn(col_name, trim(col(col_name)))
    
    # ====================================================================
    # Data Transformations
    # ====================================================================
    
    # Example transformations - adjust based on your actual data structure
    
    # 1. Standardize string values (e.g., uppercase for codes)
    # df = df.withColumn("status", upper(col("status")))
    
    # 2. Parse and validate timestamps
    # df = df.withColumn("created_at", to_timestamp(col("created_at")))
    
    # 3. Add data quality flags
    # df = df.withColumn(
    #     "data_quality_flag",
    #     when(col("some_field").isNull(), "INCOMPLETE")
    #     .otherwise("COMPLETE")
    # )
    
    # 4. Filter out invalid records
    # df = df.filter(col("data_quality_flag") == "COMPLETE")
    
    logger.info(f"After transformations: {df.count()} records")
    
    # ====================================================================
    # Write Processed Data
    # ====================================================================
    
    # Convert back to DynamicFrame
    processed_dynamic_frame = DynamicFrame.fromDF(df, glueContext, "processed_dynamic_frame")
    
    # Write to processed bucket in Parquet format with partitioning
    target_path = f"s3://{args['TARGET_BUCKET']}/data/"
    logger.info(f"Writing processed data to: {target_path}")
    
    glueContext.write_dynamic_frame.from_options(
        frame=processed_dynamic_frame,
        connection_type="s3",
        connection_options={
            "path": target_path,
            # Partition by date if you have a date column
            # "partitionKeys": ["year", "month", "day"]
        },
        format="parquet",
        transformation_ctx="write_processed"
    )
    
    logger.info("Job completed successfully")
    
except Exception as e:
    logger.error(f"Job failed with error: {str(e)}")
    raise

finally:
    job.commit()