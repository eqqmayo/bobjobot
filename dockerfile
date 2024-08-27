# Use the official Dart image as the base image
FROM dart:stable AS build

# Set the working directory
WORKDIR /app

# Copy the pubspec files and get dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the application code
COPY . .

# Build the Dart application
RUN dart compile exe bin/main.dart -o /app/bin/main

# Use a minimal image to run the app
FROM scratch

# Copy the compiled executable from the build stage
COPY --from=build /app/bin/main /app/bin/main

# Expose the port the app runs on
EXPOSE 8080

# Command to run the application
CMD ["/app/bin/main"]