import matplotlib.pyplot as plt
import numpy as np
import serial
import time


def read_data(ser):
    i = 0
    data_arr = []
    allignment = False

    while i < 4:
        data = ser.read()  # Read 1 byte
        if int.from_bytes(data) == 0:
            allignment = True
        if allignment:
            data_arr.append(int.from_bytes(data))
            i += 1
            if i == 4:
                return data_arr


def continuous_radar_uart(port, baud_rate):
    # Start UART connection
    ser = serial.Serial(port, baud_rate)

    # Create radar screen
    fig, ax = plt.subplots(figsize=(6, 6))
    fig.patch.set_facecolor('black')
    ax.set_facecolor('black')
    ax.set_aspect('equal')

    # Set circular boundaries
    ax.set_xlim(-360, 360)
    ax.set_ylim(-360, 360)

    # Draw circular grids
    circle_radii = [50, 100, 150, 200, 250, 300]
    for radius in circle_radii:
        circle = plt.Circle((0, 0), radius, color='green', fill=False, linewidth=0.5)
        ax.add_artist(circle)

    # Draw angular lines
    for angle in range(0, 360, 30):
        x_end = 300 * np.cos(np.radians(angle))
        y_end = 300 * np.sin(np.radians(angle))
        ax.plot([0, x_end], [0, y_end], color='green', linewidth=0.5)

    # Radar sweeping line and detected objects
    radar_line, = ax.plot([], [], color='lime', linewidth=1)
    object_scatter = ax.scatter([], [], color='red', s=10)

    angle = 0  # Start angle of the radar line
    object_positions = []  # To store detected objects

    try:
        while True:
            # Update radar sweeping line
            x_end = 300 * np.cos(np.radians(angle))
            y_end = 300 * np.sin(np.radians(angle))
            radar_line.set_data([0, x_end], [0, y_end])

            # Increment angle
            angle += 2
            if angle >= 360:
                angle = 0

            # Read data from UART
            if ser.in_waiting > 0:  # Check if data is available
                data_arr = read_data(ser)
                angle_value = data_arr[1]
                distance = data_arr[3]

                # Calculate object position
                object_x = distance * np.cos(np.radians(angle_value))
                object_y = distance * np.sin(np.radians(angle_value))
                object_positions.append((object_x, object_y))

                # Update scatter plot with new positions
                object_scatter.set_offsets(object_positions)

            plt.pause(0.001)  # Pause for a short time to update the plot

    except KeyboardInterrupt:
        print("Radar stopped.")
    finally:
        ser.close()


# Specify UART port and baud rate
port = 'COM7'  # Change as needed
baud_rate = 9600

continuous_radar_uart(port, baud_rate)
