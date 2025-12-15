# Создание проекта
create_project gauss_filter ./gauss_filter -part xc7z020clg400-1
# set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]

# Добавление файлов источника
add_files -norecurse ../rtl/gausse_filter_axis.sv

# Создание IP-ядра
ipx::package_project -root_dir ./ip_repo -vendor user.org -library user -taxonomy /UserIP
set_property display_name "Gauss Filter 1x5" [ipx::current_core]
set_property description "Streaming Gaussian Filter 1x5 with Mirroring" [ipx::current_core]

# Добавление интерфейсов
ipx::add_bus_interface s_axis [ipx::current_core]
set_property interface_mode slave [ipx::get_bus_interfaces s_axis -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0 [ipx::get_bus_interfaces s_axis -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0 [ipx::get_bus_interfaces s_axis -of_objects [ipx::current_core]]

ipx::add_bus_interface m_axis [ipx::current_core]
set_property interface_mode master [ipx::get_bus_interfaces m_axis -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0 [ipx::get_bus_interfaces m_axis -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0 [ipx::get_bus_interfaces m_axis -of_objects [ipx::current_core]]

# Параметры
ipx::add_user_parameter WIDTH [ipx::current_core]
set_property value_resolve_type user [ipx::get_user_parameters WIDTH -of_objects [ipx::current_core]]
set_property display_name "Image Width" [ipx::get_user_parameters WIDTH -of_objects [ipx::current_core]]
set_property value 640 [ipx::get_user_parameters WIDTH -of_objects [ipx::current_core]]

ipx::add_user_parameter HEIGHT [ipx::current_core]
set_property value_resolve_type user [ipx::get_user_parameters HEIGHT -of_objects [ipx::current_core]]
set_property display_name "Image Height" [ipx::get_user_parameters HEIGHT -of_objects [ipx::current_core]]
set_property value 512 [ipx::get_user_parameters HEIGHT -of_objects [ipx::current_core]]

# Сохранение IP-ядра
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]