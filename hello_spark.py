from pyspark.sql import SparkSession


def main():
    # Initialize Spark Session
    spark = SparkSession.builder \
        .appName("HelloWorldBazel") \
        .getOrCreate()
    
    sc = spark.sparkContext
    
    # Simple operation: parallelize a list and perform a map operation
    nums = sc.parallelize([1, 2, 3, 4])
    result = nums.map(lambda x: x * x).collect()
    
    print(f"Hello, Bazel with PySpark! The result is: {result}")
    
    spark.stop()


if __name__ == '__main__':
    main()
